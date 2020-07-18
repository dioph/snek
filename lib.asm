;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                  CONSTANTS                                  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SYS_EXIT:       equ     1
SYS_READ:       equ     3
SYS_WRITE:      equ     4

STDIN:          equ     0
STDOUT:         equ     1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                 SUBROUTINES                                 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; -----------------------------------------------------------------------------
; uint strlen (char *)
; returns the length of the null-terminated string pointed by eax
; -----------------------------------------------------------------------------
strlen:
        ; save ebx
        push    dword   ebx
        mov     dword   ebx, eax
.nextchar:
        cmp     byte    [eax], 0
        je      short   .end
        inc     dword   eax
        jmp     short   .nextchar
.end:
        ; eax = string.end() - string.begin()
        sub     dword   eax, ebx
        ; recover ebx
        pop     dword   ebx
        ret
; -----------------------------------------------------------------------------
; void printstr (char *)
; prints the null-terminated string pointed by eax
; -----------------------------------------------------------------------------
printstr:
        ; save registers in the stack
        push    dword   eax
        push    dword   ebx
        push    dword   ecx
        push    dword   edx
        ; edx = strlen(eax)
        push    dword   eax
        call    near    strlen
        mov     dword   edx, eax
        pop     dword   eax
        ; sys_write(eax)
        mov     dword   ecx, eax
        mov     dword   ebx, STDOUT
        mov     dword   eax, SYS_WRITE
        int     byte    0x80
        ; recover registers from the stack
        pop     dword   edx
        pop     dword   ecx
        pop     dword   ebx
        pop     dword   eax
        ret
; -----------------------------------------------------------------------------
; void printuint (uint)
; prints 32-bit unsigned int contained in eax
; -----------------------------------------------------------------------------
printuint:
        push    dword   eax
        push    dword   ebx
        push    dword   ecx
        push    dword   edx
        xor     dword   ecx, ecx
.divloop:
        inc     dword   ecx
        ; stack.push(char(eax % 10))
        xor     dword   edx, edx
        mov     dword   ebx, 10
        div     dword   ebx
        add     dword   edx, '0'
        push    dword   edx
        cmp     dword   eax, 0
        jne     short   .divloop
.printloop:
        dec     dword   ecx
        mov     dword   eax, esp
        call    near    printstr
        pop     dword   eax
        cmp     dword   ecx, 0
        jne     short   .printloop
.end:
        pop     dword   edx
        pop     dword   ecx
        pop     dword   ebx
        pop     dword   eax
        ret
; -----------------------------------------------------------------------------
; void printint (int)
; prints 32-bit signed int contained in eax
; -----------------------------------------------------------------------------
printint:
        push    dword   ebx
        test    dword   eax, eax
        jns     short   .print
        push    dword   eax
        mov     dword   eax, '-'
        push    dword   eax
        mov     dword   eax, esp
        call    near    printstr
        pop     dword   eax
        pop     dword   eax
        mov     dword   ebx, -1
        imul    dword   ebx
.print:
        call    near    printuint
        pop     dword   ebx
        ret
; -----------------------------------------------------------------------------
; void printnl ()
; prints a line feed char
; -----------------------------------------------------------------------------
printnl:
        push    dword   eax
        mov     dword   eax, 0x0A
        push    dword   eax
        mov     dword   eax, esp
        call    near    printstr
        pop     dword   eax
        pop     dword   eax
        ret
; -----------------------------------------------------------------------------
; uint atoi (char *)
; converts null-terminated string pointed by eax to int
; -----------------------------------------------------------------------------
atoi:
        ; save context
        push    dword   ebx
        push    dword   edx
        push    dword   esi
        mov     dword   ebx, eax
        xor     dword   eax, eax
        xor     dword   esi, esi
.nextbyte:
        xor     dword   edx, edx
        mov     byte    dl, [ebx+esi]
        cmp     byte    dl, '0'
        jb      short   .end
        cmp     byte    dl, '9'
        ja      short   .end
        sub     byte    dl, '0'
        add     dword   eax, edx
        mov     dword   edx, 10
        mul     dword   edx
        inc     dword   esi
        jmp     short   .nextbyte
.end:
        xor     dword   edx, edx
        mov     dword   ebx, 10
        div     dword   ebx
        ; recover context
        pop     dword   esi
        pop     dword   edx
        pop     dword   ebx
        ret
