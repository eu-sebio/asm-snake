includelib ucrt.lib
extern _kbhit:proc      ; External declaration for kbhit (checks if a key has been pressed)
extern _getch:proc      ; External declaration for getch (reads a character, unbuffered, no echo)
extern putchar:proc     ; External declaration for putchar (writes a character to the console)

.code
main1 PROC
    sub rsp, 40        ; Allocate 32 bytes shadow space + 8 bytes for 16-byte stack alignment
    ; Wait for a key press using kbhit
wait_key:
    mov ecx, '*'       ; Get ready to print a asterisk (not strictly necessary)
    call putchar       ; Print a asterisk to indicate waiting  (not strictly necessary)
    call _kbhit        ; Call kbhit to check if a key has been pressed
    test eax, eax      ; Test the return value
    jz wait_key        ; If zero (no key pressed), loop and check again

    ; Read the character
    call _getch        ; Call getch to read the pressed key (character in AL/EAX)
    mov ecx, eax       ; Move the character to ECX (putchar expects it in ECX)

    ; Write the character back
    call putchar       ; Call putchar to write the character to the console
    add rsp, 40        ; Restore the stack pointer
    ; Return 0
    xor eax, eax       ; Set return value to 0
    ret
main1 ENDP
END
