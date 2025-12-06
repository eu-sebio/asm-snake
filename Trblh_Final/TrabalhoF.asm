includelib ucrt.lib
includelib legacy_stdio_definitions.lib
includelib user32.lib 
includelib msvcrt.lib

; --- Funções do Windows ---
extrn GetStdHandle : proc
extrn SetConsoleCursorInfo : proc
extrn SetConsoleTitleA : proc
extrn SetConsoleCursorPosition : proc 
extrn ReadConsoleInputA : proc       
extrn GetAsyncKeyState : proc     
extrn Sleep : proc                   
extrn ExitProcess : proc
extrn rand : proc
extrn srand : proc
extrn time : proc
extrn printf : proc

; --- Funções de C ---
extrn _kbhit : proc
extrn _getch : proc
extrn putchar : proc

; --- Estruturas ---
CONSOLE_CURSOR_INFO STRUCT
    dwSize      DWORD ?
    bVisible    DWORD ?
CONSOLE_CURSOR_INFO ENDS

;;;;;;;;;;;;;;;;;     DATA    ;;;;;;;;;;;;;;;;;;

.data
    STD_OUTPUT_HANDLE equ -11
    STD_INPUT_HANDLE  equ -10
    
    ; Strings
    tituloJanela db "SNAKE GAME", 0
    msgStart0 db "                                           --- Welcome to the Snake Game ---                                    ", 0
    msgStart1 db "            -> Your goal is to eat the fruit (*) to add points, and as your score increases so does the Snake!", 0
    msgStart15 db "            -> You lose by biting yourself or the walls, so be careful!! (The Snake is vegan)", 0
    msgStart2 db "            -> To change directions use the arrow keys or AWSD                                               ", 0
    msgStart3 db "                                                   Press any key to start                                           ", 0
    apagaTexto db "                                                                                                                                                  ", 0
    printedScore db "Score: %d   ", 10, 0
    msgEnd0 db "                                                   --- Game over ---", 0
    msgEnd1 db "                                                  -> Your Score is: %d ", 10, 0
    msgEnd2 db "                                            Press any key to leave (Bye bye)", 0
    
    ; Variáveis
    hStdOut qword 0
    hStdIn qword 0
    counter db 0
    speed db 100
    points qword 0

    cursorInfo   CONSOLE_CURSOR_INFO <100, 0> 

    ; Posição do cursor
    posX byte 40
    posY byte 12

    foodX byte 0
    foodY byte 0

    ;variavel para saber a direçao
    currentDir   byte 0   ; 0=Left, 1=Up, 2=Right, 3=Down

;;;;;;;;;;;;;;;;;     CODE    ;;;;;;;;;;;;;;;;;;

.code
main proc

    sub rsp, 40             

    mov rcx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov hStdOut, rax

    ;--- Seed para a função de randomização
    mov rcx, 0
    call time
    mov rcx, rax
    call srand


    lea rcx, tituloJanela
    call SetConsoleTitleA

    call cursor
    call mensagemInicial
    call gameWindow
    call foodRandomizer
    call scoreBoard

    ;--- Direção random da Snake
    call rand           ; Gera número
    and rax, 3          ; Filtra para 0-3
    mov currentDir, al                ; chamar aqui a função random



    call game
    call endingScreen
    mov rcx, 0
    call ExitProcess
main endp

;;;;;;;;;;;;;;;;;  END OF MAIN ;;;;;;;;;;;;;;;;;


endingScreen proc
    sub rsp, 40
    mov r12, 0
    Apaga:
        mov posX, 0
        mov rax, r12
        mov posY, al
        call moverCursor
        
        lea rcx, apagaTexto
        call printf

        inc r12
        cmp r12, 26
        jl Apaga

    lea rbx, msgEnd0
    mov posX, 0
    mov posY, 10
    call moverCursor
    lea rcx, msgEnd0
    call printf

    mov posX, 0
    mov posY, 13
    call moverCursor
    lea rcx, msgEnd1        ; "Your Score is: %d"
    mov rdx, points         ; Passamos o valor dos pontos para RDX
    call printf             ; O printf substitui o %d pelo valor de RDX
    
    mov posX, 0
    mov posY, 16
    call moverCursor
    lea rcx, msgEnd2
    call printf

ClearLastKey:
    call _kbhit             ; Há tecla no buffer?
    test eax, eax
    jz WaitKey              ; Se não (0), pode ir esperar
    call _getch             ; Se sim, consome a tecla (deita fora)
    jmp ClearLastKey           ; Repete até limpar tudo

WaitKey:
    call _kbhit 
    test eax, eax           
    jz WaitKey
    call _getch

    add rsp, 40
    ret
endingScreen endp

scoreBoard proc
    push r12
    push r13
    sub rsp, 40

    movzx r12, posX
    movzx r13, posY

    mov posX, 2
    mov posY, 26
    call moverCursor
    lea rcx, printedScore
    mov rdx, points
    call printf

    mov rax, r13
    mov posY, al
    mov rax, r12
    mov posX, al

    add rsp, 40
    pop r13
    pop r12

    ret
scoreBoard endp

foodRandomizer proc
    push r12
    push r13
    sub rsp, 40
   
    
    ;--- salva os dados que podem afetar a Snake
    movzx r12, posX
    movzx r13, posY

    mov rbx, 2Ah

    call rand
    xor rdx, rdx
    mov rcx, 78
    div rcx
    inc rdx
    mov posX, dl
    mov foodX, dl

    call rand
    xor rdx, rdx
    mov rcx, 23
    div rcx
    inc rdx
    mov posY, dl
    mov foodY, dl

    call moverCursor
    mov rcx, rbx
    call putchar

    mov rax, r13
    mov posY, al
    mov rax, r12
    mov posX, al
    
    add rsp, 40
    pop r13
    pop r12
    ret
foodRandomizer endp


gameWindow proc
    sub rsp, 40
    
    mov counter, 0
    mov posX, 0
    mov posY, 0
    mov rbx, 23h

    Horizontal1:
        call moverCursor
        mov rcx, rbx           
        call putchar
        cmp counter, 79
        jne IncrementarX
        cmp posY, 0
        jne IrParaVertical

        mov posX, 0             
        mov posY, 24
        mov counter, 0
        jmp Horizontal1         

    IncrementarX:
        inc counter
        inc posX
        jmp Horizontal1         
    
    IrParaVertical:
        mov posX, 0
        mov posY, 0
        mov counter, 0
        jmp Vertical1
    
    Vertical1: 
        call moverCursor
        mov rcx, rbx
        call putchar
        cmp counter, 24
        jne IncrementarY
        cmp posX, 0
        jne Fim
        mov posX, 79
        mov posY, 0
        mov counter, 0
        jmp Vertical1
    
    IncrementarY:
        inc counter
        inc posY
        jmp Vertical1

    Fim:
        mov posX, 40
        mov posY, 12

    add rsp, 40
    ret
gameWindow endp

cursor proc
    sub rsp, 40

    mov rcx, hStdOut        ; RCX = Identificador da janela da consola (ecrã)
    lea rdx, cursorInfo     ; RDX = Endereço da struct que diz "visível = 0" (falso)
    call SetConsoleCursorInfo ; Chama a função do Windows: "Aplica estas configurações"

    add rsp, 40
    ret

cursor endp

moverCursor proc
    push rbx                ; Salva o valor original de RBX
    sub rsp, 32
    
    ; 1. Tratar Y (High part)
    xor rax, rax
    mov al, posY
    shl eax, 16             ; Y nos bits altos

    ; 2. Tratar X (Low part)
    xor rbx, rbx
    mov bl, posX            ; X fica nos bits inferiores

    ; 3. Combinar
    or rax, rbx             ; EAX agora é Y << 16 | X
    
    ; 4. Chamar API
    mov rcx, hStdOut        ; Handle
    mov rdx, rax            ; Posição (passada por valor no RDX)
    call SetConsoleCursorPosition

    add rsp, 32
    pop rbx                 ; Restaura RBX (Crucial para não crashar main)
    ret
moverCursor endp

mensagemInicial proc
    sub rsp, 40

    mov posX, 0
    mov posY, 10
    call moverCursor
    lea rbx, msgStart0      ; Carrega a frase
    call ImprimirFraseAtual ; Chama a rotina que imprime o que está em RBX

    mov posX, 0
    mov posY, 13
    call moverCursor
    lea rbx, msgStart1
    call ImprimirFraseAtual

    mov posX, 0
    mov posY, 14
    call moverCursor
    lea rbx, msgStart15
    call ImprimirFraseAtual

    mov posX, 0
    mov posY, 15
    call moverCursor
    lea rbx, msgStart2
    call ImprimirFraseAtual

    mov posX, 0
    mov posY, 18
    call moverCursor
    lea rbx, msgStart3
    call ImprimirFraseAtual

    jmp WaitKey

ImprimirFraseAtual:
    xor rcx, rcx
    mov cl, [rbx]
    test cl, cl
    jz FimImprimir      ; Se for 0, acabou esta frase
    call putchar
    inc rbx
    jmp ImprimirFraseAtual
FimImprimir:
    ret


    ; O jogo fica parado aqui até alguém carregar numa tecla.
WaitKey:
    call _kbhit             ; Verifica: "Há alguma tecla no buffer?" (Não bloqueia)
                            ; Retorna 1 em EAX se houver, 0 se não houver.
    
    test eax, eax           ; Compara o retorno.
    jz WaitKey              ; Se for 0 (ninguém tocou em nada), repete o loop infinitamente.
    

    ; --- Apagar as instruções do ecrã assim que houver clique---

mov r12, 0
    LimparInicio:
        mov posX, 0
        mov rax, r12
        mov posY, al
        call moverCursor
        
        lea rcx, apagaTexto
        call printf

        inc r12
        cmp r12, 26
        jl LimparInicio

   ; --- Preparar a posição da cobra ---    
    mov posX, 40
    mov posY, 12
    mov counter, 0


    call _getch             ; Se chegamos aqui, alguém tocou numa tecla!
                            ; Chamamos _getch para "comer" essa tecla e limpar o buffer.
                            ; Se não fizermos isto, o buffer fica sujo para o jogo.
    add rsp, 40
    ret
mensagemInicial endp


game proc

    ; =========================================================================
    ; PARTE 4: O LOOP DO JOGO (O CORAÇÃO)
    ; A lógica aqui é: Apagar Posição Velha -> Calcular Nova -> Desenhar Nova
    ; =========================================================================
    sub rsp, 40

GameLoop:
    ; --- A. APAGAR O RASTRO ---
    ; Antes de movermos a cobra, temos de apagar onde ela estava no frame anterior.
    
    call moverCursor        ; Move o cursor interno do Windows para (posX, posY)
    
    mov rcx, 32             ; 32 é o código ASCII para ESPAÇO (' ')
    call putchar            ; Escreve um espaço em branco.
                            ; Visualmente, isto "apaga" o 'O' que estava lá.

    ; --- B. VERIFICAR INPUT (Teclado) ---
    ; Aqui usamos GetAsyncKeyState porque queremos saber se a tecla está 
    ; pressionada AGORA, permitindo movimento contínuo e rápido.

     ; ESQUERDA (Seta ou A)
    mov rcx, 25h
    call GetAsyncKeyState   ; Pergunta ao Windows o estado dessa tecla
    test ax, 8000h          ; O bit mais alto (8000h) diz se está pressionada agora.
    jnz SetLeft             ; Se não clicou, verifica próxima
    mov rcx, 41h            ; 'A'
    call GetAsyncKeyState
    test ax, 8000h
    jnz SetLeft

   ; CIMA (Seta ou W)
    mov rcx, 26h
    call GetAsyncKeyState
    test ax, 8000h
    jnz SetUp
    mov rcx, 57h            ; 'W'
    call GetAsyncKeyState
    test ax, 8000h
    jnz SetUp

    ; DIREITA (Seta ou D)
    mov rcx, 27h
    call GetAsyncKeyState
    test ax, 8000h
    jnz SetRight
    mov rcx, 44h            ; 'D'
    call GetAsyncKeyState
    test ax, 8000h
    jnz SetRight

    ; BAIXO (Seta ou S)
    mov rcx, 28h
    call GetAsyncKeyState
    test ax, 8000h
    jnz SetDown
    mov rcx, 53h            ; 'S'
    call GetAsyncKeyState
    test ax, 8000h
    jnz SetDown

    jmp ApplyMove           ; Nenhuma tecla nova? Mantém a direção atual

SetLeft:
    mov currentDir, 0
    jmp ApplyMove
SetUp:
    mov currentDir, 1
    jmp ApplyMove
SetRight:
    mov currentDir, 2
    jmp ApplyMove
SetDown:
    mov currentDir, 3
    jmp ApplyMove

    ; --- C. APLICAR MOVIMENTO ---
ApplyMove:
    cmp currentDir, 0
    je GoLeft
    cmp currentDir, 1
    je GoUp
    cmp currentDir, 2
    je GoRight
    cmp currentDir, 3
    je GoDown
    jmp Render

GoLeft:
    dec posX
    jmp Render
GoUp:
    dec posY                ; Cima = Y menor
    jmp Render
GoRight:
    inc posX
    jmp Render
GoDown:
    inc posY                ; Baixo = Y maior
    jmp Render

    ; --- D. RENDERIZAR ---
Render:
    call moverCursor
    mov rcx, '@'            ; cabeça da Snake
    call putchar

    ;--- verifica se a fruta foi comida

    mov al, posX            ; Carrega X da Cobra
    cmp al, foodX           ; Compara com X da Comida
    jne WallCollision            ; Se forem diferentes, salta

    ; 2. Comparar Y da Cobra com Y da Comida
    mov al, posY            ; Carrega Y da Cobra
    cmp al, foodY           ; Compara com Y da Comida
    jne WallCollision            ; Se forem diferentes, salta

    call foodRandomizer     ; Gera uma nova fruta imediatamente
    inc qword ptr [points]
    call scoreBoard

    IncreaseSpeed:
        mov rax, points
        xor rdx, rdx
        mov rbx, 6
        div rbx
        cmp rdx, 0
        jne WallCollision
        dec speed

    WallCollision:
        cmp posX, 0
        je GameOver
        cmp posX, 79
        je GameOver

        cmp posY, 0
        je GameOver
        cmp posY, 24
        je GameOver


ContinuaMovimento:
    ; --- E. VELOCIDADE ---
    movzx rcx, speed            ; 100ms initially
    call Sleep

    jmp GameLoop            ; Repete para sempre

    GameOver:
        add rsp, 40
        ret
game endp


end
