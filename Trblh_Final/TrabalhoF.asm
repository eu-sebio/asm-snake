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
    msgStart1 db "               -> Your goal is to eat the fruit (*) to add points, and as your score increases the snake becomes longer", 0
    msgStart15 db "               -> You lose by biting yourself or the walls, so be careful!! (The Snake is vegan)", 0
    msgStart2 db "               -> To change directions use the arrow keys or AWSD                                               ", 0
    msgStart3 db "                                                   Press any key to start                                           ", 0
    apagaTexto db "                                                                                                                                      ", 0
    
    ; Variáveis
    hStdOut      qword 0
    hStdIn       qword 0
    counter      db 0
    
    cursorInfo   CONSOLE_CURSOR_INFO <100, 0> 

    ; Posição do cursor
    posX         byte 40
    posY         byte 12

    ;variavel para saber a direçao
    currentDir   byte 0   ; 1=Left, 2=Up, 3=Right, 4=Down

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
    ;call gameWindow

    ;--- Direção random da Snake
    call rand           ; Gera número
    and rax, 3          ; Filtra para 0-3
    inc rax
    mov currentDir, al                ; chamar aqui a função random



    call game

    mov rcx, 0
    call ExitProcess
main endp

;;;;;;;;;;;;;;;;;  END OF MAIN ;;;;;;;;;;;;;;;;;





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
    ; =========================================================================
    ; PARTE 1: PREPARAÇÃO DO AMBIENTE
    ; O objetivo aqui é esconder aquele cursor que fica a piscar "_" na consola
    ; para o jogo ficar mais limpo visualmente.
    ; =========================================================================
    sub rsp, 40

    mov rcx, hStdOut        ; RCX = Identificador da janela da consola (ecrã)
    lea rdx, cursorInfo     ; RDX = Endereço da struct que diz "visível = 0" (falso)
    call SetConsoleCursorInfo ; Chama a função do Windows: "Aplica estas configurações"

    add rsp, 40
    ret

cursor endp

; ====================================================================
; Mover Cursor do Windows
; ====================================================================

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
    ; =========================================================================
    ; PARTE 2: ESCREVER A MENSAGEM INICIAL
    ; Aqui usamos um loop para imprimir caractere por caractere.
    ; =========================================================================
    sub rsp, 40

    lea rbx, msgStart0      ; Carrega a primeira frase
    Loop1:
        xor rcx, rcx
        mov cl, [rbx]
        test cl, cl
        jz paragrafo          ; Acabou a linha 1? Vai dar o Enter
        call putchar
        inc rbx
        jmp Loop1

    paragrafo:
        mov rcx, 10             
        call putchar
        mov rcx, 10             
        call putchar


     lea rbx, msgStart1
     Loop2:
         xor rcx, rcx
         mov cl, [rbx]
         test cl, cl
         jz paragrafo2              ; Acabou linha 2? Espera tecla
         call putchar
         inc rbx
         jmp Loop2

     paragrafo2:
        mov rcx, 10             
        call putchar

     lea rbx, msgStart15
     Loop15:
         xor rcx, rcx
         mov cl, [rbx]
         test cl, cl
         jz paragrafo15              ; Acabou linha 2? Espera tecla
         call putchar
         inc rbx
         jmp Loop15

     paragrafo15:
        mov rcx, 10             
        call putchar
     
    lea rbx, msgStart2      ; Carrega a primeira frase
    Loop3:
        xor rcx, rcx
        mov cl, [rbx]
        test cl, cl
        jz paragrafo3          ; Acabou a linha 1? Vai dar o Enter
        call putchar
        inc rbx
        jmp Loop3

     paragrafo3:
        mov rcx, 10             
        call putchar
        mov rcx, 10             
        call putchar

     lea rbx, msgStart3
     Loop4:
         xor rcx, rcx
         mov cl, [rbx]
         test cl, cl
         jz WaitKey              ; Acabou linha 2? Espera tecla
         call putchar
         inc rbx
         jmp Loop4

    ; =========================================================================
    ; PARTE 3: ESPERAR PELO JOGADOR
    ; O jogo fica parado aqui até alguém carregar numa tecla.
    ; =========================================================================
WaitKey:
    call _kbhit             ; Verifica: "Há alguma tecla no buffer?" (Não bloqueia)
                            ; Retorna 1 em EAX se houver, 0 se não houver.
    
    test eax, eax           ; Compara o retorno.
    jz WaitKey              ; Se for 0 (ninguém tocou em nada), repete o loop infinitamente.
    

    ; --- Apagar as instruções do ecrã assim que houver clique---

    Linha0:
        mov posX, 0
        mov posY, 0
        call moverCursor        ; Vai para (0,0)
        lea rbx, apagaTexto     ; Carrega a "borracha"
        inc counter
        jmp Apagar   ; Escreve espaços

    Linha1:
        mov posX, 0
        mov posY, 2
        call moverCursor        ; Vai para (0,0)
        lea rbx, apagaTexto     ; Carrega a "borracha"
        inc counter
        jmp Apagar   ; Escreve espaços

     Linha15:
        mov posX, 0
        mov posY, 3
        call moverCursor        ; Vai para (0,0)
        lea rbx, apagaTexto     ; Carrega a "borracha"
        inc counter
        jmp Apagar   ; Escreve espaços
    
    Linha2:
        mov posX, 0
        mov posY, 4             
        call moverCursor        
        lea rbx, apagaTexto
        inc counter
        jmp Apagar   

    Linha3:
        mov posX, 0
        mov posY, 6             
        call moverCursor        
        lea rbx, apagaTexto
        inc counter
        jmp Apagar

    Apagar:
        xor rcx, rcx
        mov cl, [rbx]
        test cl, cl
        jz FimApagar
        call putchar
        inc rbx
        jmp Apagar

    FimApagar:
        cmp counter, 1
        je Linha1
        cmp counter, 2
        je Linha15
        cmp counter, 3
        je Linha2
        cmp counter, 4
        je Linha3

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
    mov rcx, '@'            ; Cobra
    call putchar

    ; --- E. VELOCIDADE ---
    mov rcx, 100            ; 100ms
    call Sleep

    jmp GameLoop            ; Repete para sempre

    ; (Este ponto nunca é atingido num loop infinito)
    add rsp, 40
    ret
game endp


end


end
