%include "src/lib.asm"

section .data
msg:            db      'Hello world!', 10, 0
        
section .text
global _start

_start:
        mov     dword   eax, msg
        call    near    printstr

        mov     dword   eax, SYS_EXIT
        mov     dword   ebx, 0
        int     byte    0x80
        
