;António Pereira Nº 66241
;Alexandre Morais Nº 75162
;André Eusébio Nº 68181

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
    ; (o visual studio não permitiu incluir o windows.inc, que era necessário para permitir esconder o rato,
    ; porque não fazia parte do MASM original )

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
    namingGroup db "                          Antonio Pereira N.66241, Alexandre Morais N.75162, Andre Eusebio N.68181", 0
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

    ;posição
    posX byte 40
    posY byte 12

    foodX byte 0
    foodY byte 0

    ;cobra
    SnakeBody  dw 400 dup(0) ;200 segmentos * 2 coordenadas * 2 bytes por coordenada = 800 bytes
    snakeLength qword 1 ;começa só com a cabeça

    ;variavel para saber a direçao
    currentDir   byte 0   ; 0=Left, 1=Up, 2=Right, 3=Down

;;;;;;;;;;;;;;;;CODE;;;;;;;;;;;;;

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
    mov currentDir, al

    ; Initialize the head in the array
    movzx rax, posX
    mov SnakeBody[0], ax    ; Store X 
    movzx rax, posY
    mov SnakeBody[2], ax    ; Store Y

    call game
    call endingScreen
    mov rcx, 0
    call ExitProcess
main endp


;   *   @+++++++++++++++++++++++++++++++++++++++++++++++++++++
;   IMPRIME A MENSAGEM FINAL                                 +
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
    call _kbhit             ; verifica se há alguma tecla no buffer
    test eax, eax
    jz WaitKey              ;se der zero então vai para o ciclo de espera
    call _getch             ; se houver, então limpa o buffer
    jmp ClearLastKey        ; repete para garantir que limpa tudo

WaitKey:
    call _kbhit 
    test eax, eax           
    jz WaitKey
    call _getch

    add rsp, 40
    ret
endingScreen endp

;   *   @+++++++++++++++++++++++++++++++++++++++++++++++++++++
;   IMPRIME UM CONTADOR DE PONTUAÇÃO                         +
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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

;   *   @+++++++++++++++++++++++++++++++++++++++++++++++++++++
;   GERA FRUTA NUM SSITIO ALEATÓRIO DENTRO DAS PAREDES       +
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
foodRandomizer proc
    push r12
    push r13
    sub rsp, 40

GenerateNewFruit:

    ; Guardar posição atual
    movzx r12, byte ptr posX
    movzx r13, byte ptr posY

    mov rbx, 2Ah            ; '*'

    ; --------- RANDOM X ---------
    call rand
    xor rdx, rdx
    mov rcx, 78
    div rcx
    inc dl
    mov byte ptr foodX, dl

    ; --------- RANDOM Y ---------
    call rand
    xor rdx, rdx
    mov rcx, 23
    div rcx
    inc dl
    mov byte ptr foodY, dl

    ; --------- VALIDAR SE ESTÁ EM CIMA DA COBRA ---------
    xor rcx, rcx

CheckIfOnSnake:
    cmp rcx, snakeLength
    jae PositionOK

    mov rax, rcx
    shl rax, 2

    ; comparar X
    mov ax, WORD PTR SnakeBody[rax]
    xor bx, bx
    mov bl, byte ptr foodX
    cmp ax, bx
    jne NextSeg

    ; comparar Y
    mov ax, WORD PTR SnakeBody[rax+2]
    xor bx, bx
    mov bl, byte ptr foodY
    cmp ax, bx
    jne NextSeg

    jmp GenerateNewFruit

NextSeg:
    inc rcx
    jmp CheckIfOnSnake

PositionOK:

    ; --------- DESENHAR FRUTA ---------
    mov al, byte ptr foodX
    mov byte ptr posX, al
    mov al, byte ptr foodY
    mov byte ptr posY, al

    call moverCursor
    mov rcx, 2Ah     ; '*'
    call putchar

    ; --------- RESTAURAR POS ---------
    mov byte ptr posX, r12b
    mov byte ptr posY, r13b

    add rsp, 40
    pop r13
    pop r12
    ret
foodRandomizer endp

;   *   @+++++++++++++++++++++++++++++++++++++++++++++++++++++
;   IMPRIME AS PAREDES                                       +
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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

;   *   @+++++++++++++++++++++++++++++++++++++++++++++++++++++
;   RECONHECE O CURSOR                                       +
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
cursor proc
    sub rsp, 40

    mov rcx, hStdOut        ; RCX = Identificador da janela
    lea rdx, cursorInfo
    call SetConsoleCursorInfo ; Chama a função do Windows que aplica estas configuraçoes

    add rsp, 40
    ret
cursor endp

;   *   @+++++++++++++++++++++++++++++++++++++++++++++++++++++
;   PERMITE MOVER O CURSOR                                   +
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
moverCursor proc
    push rbx                ; salva o valor original de RBX
    sub rsp, 32
    
    ; y (high part)
    xor rax, rax
    mov al, posY
    shl eax, 16             ; y nos bits altos

    ; x (low part)
    xor rbx, rbx
    mov bl, posX            ; x fica nos bits inferiores

    or rax, rbx             ; eax agora é Y << 16 | X
    
    ; coloca o cursor no sitio
    mov rcx, hStdOut        ; handle
    mov rdx, rax            ; posiçao (passada por valor no RDX)
    call SetConsoleCursorPosition

    add rsp, 32
    pop rbx
    ret
moverCursor endp

;   *   @+++++++++++++++++++++++++++++++++++++++++++++++++++++
;   IMPRIME A MENSAGEM INICIAL                               +
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
mensagemInicial proc
    sub rsp, 40

    mov posX, 0
    mov posY, 10
    call moverCursor
    lea rbx, msgStart0      ; carrega a frase em rbx
    call ImprimirFraseAtual

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

    mov posX, 0
    mov posY, 25
    call moverCursor
    lea rbx, namingGroup
    call ImprimirFraseAtual

    jmp WaitKey

ImprimirFraseAtual:
    xor rcx, rcx
    mov cl, [rbx]
    test cl, cl
    jz FimImprimir      ; se for 0, acabou esta frase
    call putchar
    inc rbx
    jmp ImprimirFraseAtual
    FimImprimir:
        ret

    ; o jogo fica parado aqui até alguém carregar numa tecla

WaitKey:
    call _kbhit             ; verifica se há alguma tecla no buffer
                            ; retorna 1 em eax se houver, 0 se não houver
    
    test eax, eax           ; compara o retorno
    jz WaitKey              ; se for 0 não houve click e repeteo WaitKey
    

    ; --- apagar o ecrã inicial assim que houver clique---
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

    call _getch             ; _getch para limpar o buffer

    add rsp, 40
    ret
mensagemInicial endp

;   *   @+++++++++++++++++++++++++++++++++++++++++++++++++++++
;   MECÂNICA DO JOGO                                         +
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
game proc
    sub rsp, 40

GameLoop:
    ; --- ERASE THE TAIL ---
    

    mov rcx, snakeLength
    dec rcx
    shl rcx, 2
    
    ; Move cursor to Tail X, Y
    xor rdx, rdx
    xor rax, rax
    
    mov dx, SnakeBody[rcx]      ; load tail X
    mov posX, dl
    mov dx, SnakeBody[rcx+2]    ; load tail Y
    mov posY, dl
    
    call moverCursor
    mov rcx, 32                 ; ' ' space
    call putchar

    ; --- RESTORE HEAD COORDS FOR CALCULATION ---
    ; maing sure that posX and posY match the current Head
    mov ax, SnakeBody[0]
    mov posX, al
    mov ax, SnakeBody[2]
    mov posY, al

    ; --- INPUT ---
    mov rcx, 25h                ; left arrow
    call GetAsyncKeyState
    test ax, 8000h
    jnz SetLeft
    
    mov rcx, 26h                ; up arrow
    call GetAsyncKeyState
    test ax, 8000h
    jnz SetUp
    
    mov rcx, 27h                ; right arrow
    call GetAsyncKeyState
    test ax, 8000h
    jnz SetRight
    
    mov rcx, 28h                ; down arrow
    call GetAsyncKeyState
    test ax, 8000h
    jnz SetDown
    
    ; W, A, S, D support
    mov rcx, 41h ; A
    call GetAsyncKeyState
    test ax, 8000h
    jnz SetLeft

    mov rcx, 57h ; W
    call GetAsyncKeyState
    test ax, 8000h
    jnz SetUp

    mov rcx, 44h ; D
    call GetAsyncKeyState
    test ax, 8000h
    jnz SetRight

    mov rcx, 53h ; S
    call GetAsyncKeyState
    test ax, 8000h
    jnz SetDown

    jmp ApplyMove  ; continue last movement

SetLeft:
    cmp currentDir, 2       ; Are we currently going Right?
    je ApplyMove            ; If yes, ignore this input
    mov currentDir, 0       ; Otherwise, set direction to Left
    jmp ApplyMove

SetUp:
    cmp currentDir, 3
    je ApplyMove
    mov currentDir, 1
    jmp ApplyMove

SetRight:
    cmp currentDir, 0
    je ApplyMove
    mov currentDir, 2 
    jmp ApplyMove

SetDown:
    cmp currentDir, 1
    je ApplyMove
    mov currentDir, 3
    jmp ApplyMove

ApplyMove:
    ; --- SHIFT THE BODY ARRAY ---
    ; body history is shifted and then the posX and posY is updated
    call UpdateBodyArr

    ; --- CALCULATE NEW HEAD POS ---
    cmp currentDir, 0
    je GoLeft
    cmp currentDir, 1
    je GoUp
    cmp currentDir, 2
    je GoRight
    cmp currentDir, 3
    je GoDown

GoLeft:  dec posX
         jmp SaveHead
GoUp:    dec posY
         jmp SaveHead
GoRight: inc posX
         jmp SaveHead
GoDown:  inc posY
         jmp SaveHead

SaveHead:
    ; store the new Head position into Array[0]
    movzx rax, posX
    mov SnakeBody[0], ax
    movzx rax, posY
    mov SnakeBody[2], ax

    ; --- CHECK COLLISIONS ---
    
    ; self collision
    call CheckSelfCollision
    cmp rax, 1
    je GameOver

    ; wall Collision
    cmp posX, 0
    je GameOver
    cmp posX, 79
    je GameOver
    cmp posY, 0
    je GameOver
    cmp posY, 24
    je GameOver

    ; --- DRAW HEAD ---
    call moverCursor
    mov rcx, '@'
    call putchar
    
    cmp snakeLength, 1
    jle CheckFruit
    
    ; move cursor to SnakeBody[4]
    mov ax, SnakeBody[4]
    mov posX, al
    mov ax, SnakeBody[6]
    mov posY, al
    call moverCursor
    mov rcx, 2Bh
    call putchar
    
    ; restore Head Pos to the coordinates
    mov ax, SnakeBody[0]
    mov posX, al
    mov ax, SnakeBody[2]
    mov posY, al

    ; --- FRUIT LOGIC ---
CheckFruit:
    mov al, posX
    cmp al, foodX
    jne DelayLoop
    
    mov al, posY
    cmp al, foodY
    jne DelayLoop

    ; --- ATE FRUIT ---
    call foodRandomizer
    inc qword ptr [points]
    
    ; GROW THE SNAKE/INCREASE SPEED
    cmp snakeLength, 200    ; Max Check
    jge SkipGrow
    cmp speed, 5
    je IncSnakeLenght
    sub speed, 5
    IncSnakeLenght:
        inc snakeLength
SkipGrow:
    call scoreBoard
    
DelayLoop:
    movzx rcx, speed
    call Sleep
    jmp GameLoop

GameOver:
    add rsp, 40
    ret
game endp

;   *   @+++++++++++++++++++++++++++++++++++++++++++++++++++++
;   ATUALIZA O ARRAY DO CORPO DA SNAKE                       +
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
UpdateBodyArr proc
    cmp snakeLength, 1
    jle EndUpdate
    
    mov rcx, snakeLength
    dec rcx
    
    ShiftLoop:
        mov rax, rcx
        shl rax, 2
        mov rbx, rax
        sub rbx, 4
        
        mov dx, SnakeBody[rbx]
        mov SnakeBody[rax], dx
        mov dx, SnakeBody[rbx+2]
        mov SnakeBody[rax+2], dx
        
        dec rcx
        jnz ShiftLoop
        
    EndUpdate:
    ret
UpdateBodyArr endp

;   *   @+++++++++++++++++++++++++++++++++++++++++++++++++++++
;   VERIFICA SE OCORREU UMA COLISÃO COM O PRÓPRIO CORPO      +
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CheckSelfCollision proc
    cmp snakeLength, 4
    jl NoCollision
    
    mov rcx, 1
    
    CheckLoop:
        cmp rcx, snakeLength
        jge NoCollision
        
        mov rax, rcx
        shl rax, 2
        
        mov dx, SnakeBody[rax]
        cmp dx, SnakeBody[0]
        jne NextSeg
        
        mov dx, SnakeBody[rax+2]
        cmp dx, SnakeBody[2]
        jne NextSeg
        
        mov rax, 1
        ret

    NextSeg:
        inc rcx
        jmp CheckLoop

    NoCollision:
    xor rax, rax
    ret
CheckSelfCollision endp

end
CheckSelfCollision endp

end
