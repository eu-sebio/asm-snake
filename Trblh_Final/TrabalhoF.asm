includelib ucrt.lib
includelib legacy_stdio_definitions.lib

extern _kbhit:proc ;see class6 slides for use case
extern _getch:proc
extern putchar:proc
;extern rand: proc


.data
;SnakeDim	QWORD 1 ;(Initial size: just the head)
;SnakeDirection QWORD 0 ;(0=Up, 1=Down, 2=Left, 3=Right)
;points QWORD 0



startGameMenu db " Start ", 0




.code


proc main
    call init



endp main


;+++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
;    Game initialisation.
;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++

proc init
        call graphicMode
        call menu



init endp

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
;    Menu.
;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++

proc menu
    mov bl, 0fh
    move si, offset startGameMenu


menu endp

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
;    Graphic mode.
;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++

proc graphicMode
        push AX
        mov AL, 13h
        mov AH, 0
        int 10h
        pop AX
        ret
graphicMode endp

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
;    Draw pixel.
;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++

proc drawPixel
        push AX   
        mov AX, BP
        mov AH, 0Ch
        int 10h
        pop AX
        ret
drawPixel endp

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
;    Draw horizontal
;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++

;proc borders

    ;sub rsp, 40
    ;xor CX, CX
    ;xor R12, R12
    ;xor R13, R13
    ;mov R12, 79
    ;mov R13, 24

    
proc horizontal

     push DX                            ;push de DX, AX, CX para "proteger" o que estiver lá
     push AX 
     push CX
     cicloH:  
         cmp CX,AX
         jg fimH 
         call drawPixel
         inc CX
         jmp cicloH
     fimH:
     pop CX
     pop AX
     pop DX
     ret
endp horizontal


   ;mov CX, "#"
   ;call putchar
   ;dec R12
   ;cmp R12, 0
   ;jnz firsthorizontal
   ;
   ;
   ;xor CX, CX         ;vou fazer aqui o primeiro parágrafo
   ;mov CX, 13
   ;call putchar
   ;xor CX, CX
   ;
   ;add R12, 79        ; para voltar a usar o mesmo registo na outra horizontal
   ;add rsp, 40        ; Restore the stack pointer
   ;xor eax, eax       ; Set return value to 0


;+++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
;    Draw vertical
;
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++

proc vertical

    push DX
    push BX 
    push CX
    cicloV:  
        cmp DX,BX
        jg fimV 
        call drawPixel
        inc DX
        jmp cicloV
    fimV:
    pop CX
    pop BX
    pop DX
    ret
endp vertical


   ;mov CX, "*"
   ;call putchar
   ;dec R13
   ;cmp R13, 0
   ;jnz firstvertical
   ;xor CX, CX
   ;add R13, 24        ; para voltar a usar o mesmo registo na outra horizontal
   ;add rsp, 40        ; Restore the stack pointer
   ;xor eax, eax       ; Set return value to 0

   ;borders endp




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           STRLEN; refazer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

proc strLen 
    push si
    mov cx, 0
    loopSL: 
        mov al, byte ptr [si]
        or al, al       
        jz endSL
        inc si
        inc cx
        jmp loopSL
    endSL:
        pop si
        ret 
endp



main proc

    call graphicMode
    call borders

ret
main endp

end