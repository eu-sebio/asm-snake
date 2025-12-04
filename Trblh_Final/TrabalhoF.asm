includelib ucrt.lib
includelib legacy_stdio_definitions.lib

includelib user32.lib                ; <--- ADICIONADO: Necessário para GetAsyncKeyState

; --- Funções do Windows ---
extrn GetStdHandle : proc
extrn SetConsoleCursorInfo : proc
extrn SetConsoleTitleA : proc
extrn SetConsoleCursorPosition : proc 
extrn ReadConsoleInputA : proc       
extrn GetAsyncKeyState : proc        ; <--- Vem da user32.lib
extrn Sleep : proc                   
extrn ExitProcess : proc

; --- Funções de C ---
extrn _kbhit : proc
extrn _getch : proc
extrn putchar : proc


.data
;SnakeDim	QWORD 1 ;(Initial size: just the head)
;SnakeDirection QWORD 0 ;(0=Up, 1=Down, 2=Left, 3=Right)
;points QWORD 0

    STD_OUTPUT_HANDLE equ -11
    STD_INPUT_HANDLE  equ -10
    
    ; Strings
    tituloJanela db "SNAKE ASM - Versao Estavel", 0
    msgStart     db "Pressione uma tecla para comecar...", 0
    
    ; Variáveis
    hStdOut      qword 0
    hStdIn       qword 0
    
    cursorInfo   CONSOLE_CURSOR_INFO <100, 0> 

    ; Posição da Cobra
    posX         byte 40
    posY         byte 12




.code
main proc
    sub rsp, 40             

    ; 1. INICIALIZAÇÃO
    mov rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov hStdOut, rax

    mov rcx, STD_INPUT_HANDLE
    call GetStdHandle
    mov hStdIn, rax

    lea rcx, tituloJanela
    call SetConsoleTitleA

    mov rcx, hStdOut
    lea rdx, cursorInfo
    call SetConsoleCursorInfo

    ; 2. TELA DE INÍCIO
    lea rbx, msgStart       ; RBX é seguro usar aqui
PrintLoop:
    xor rcx, rcx            ; Limpa RCX
    mov cl, [rbx]           ; Pega apenas o byte do char
    test cl, cl             ; É zero (fim da string)?
    jz WaitKey

    call putchar
    inc rbx
    jmp PrintLoop

WaitKey:
    call _kbhit
    test eax, eax
    jz WaitKey 

    call _getch             ; Consome a tecla pressionada

    ; 3. LOOP DO JOGO
GameLoop:
    ; A. Apagar rastro (Desenha espaço na posição atual)
    call MoverCursor
    mov rcx, 32             ; ASCII Space
    call putchar

    ; B. Input
    ; DIREITA (VK_RIGHT = 0x27)
    mov rcx, 27h 
    call GetAsyncKeyState
    test ax, 8000h          ; Bit mais significativo indica tecla pressionada
    jnz MoveRight

    ; ESQUERDA (VK_LEFT = 0x25)
    mov rcx, 25h
    call GetAsyncKeyState
    test ax, 8000h
    jnz MoveLeft

    jmp Render

MoveRight:
    inc posX
    jmp Render
MoveLeft:
    dec posX
    jmp Render

    ; C. Renderizar (Desenha 'O' na nova posição)
Render:
    call MoverCursor    
    
    mov rcx, 'O'        
    call putchar

    ; D. Timing
    mov rcx, 100        
    call Sleep

    jmp GameLoop        

    ; FIM
    mov rcx, 0
    call ExitProcess
main endp

; --------------------------------------------------------------------
; Procedimento Auxiliar: MoverCursor
; --------------------------------------------------------------------
MoverCursor proc
    ; ================================================================
    ; PROTEÇÃO DE REGISTRADORES (ABI x64)
    ; RBX é "Non-volatile". Se usarmos, temos que salvar e restaurar.
    ; ================================================================
    push rbx                ; Salva o valor original de RBX

    ; Formatar RDX como 0x00YYXXXX (COORD)
    
    ; 1. Tratar Y (High part)
    xor rax, rax
    mov al, posY
    shl eax, 16             ; Move Y para os bits superiores

    ; 2. Tratar X (Low part)
    xor rbx, rbx
    mov bl, posX            ; X fica nos bits inferiores

    ; 3. Combinar
    or rax, rbx             ; EAX agora é Y << 16 | X
    
    ; 4. Chamar API
    mov rcx, hStdOut        ; Handle
    mov rdx, rax            ; Posição (passada por valor no RDX)
    call SetConsoleCursorPosition

    pop rbx                 ; Restaura RBX (Crucial para não crashar main)
    ret
MoverCursor endp

end
