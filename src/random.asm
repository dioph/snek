section .data
a:              dd      8121
c:              dd      28411
M:              dd      134456
random_mod:     dd      134456.0
random_seed:    dd      42

section .bss
randint:        resd    1

section .text
global randomInt, randomHit
; -----------------------------------------------------------------------------
; uint myRandom ()
; Linear Congruent Generator; returns a pseudo-random number between 0 and M-1
; -----------------------------------------------------------------------------
myRandom:
        ; save edx in the stack
        push    dword   edx
        ; r(i) = (a * r(i-1) + c) % M
        mov     dword   eax, [random_seed]
        mul     dword   [a]
        add     dword   eax, [c]
        xor     dword   edx, edx
        div     dword   [M]
        mov     dword   [random_seed], edx
        mov     dword   eax, [random_seed]
        ; recover edx
        pop     dword   edx
        ret
; -----------------------------------------------------------------------------
; bool randomHit (float)
; returns whether a random number in [0,1] is less than st0 (probability)
; -----------------------------------------------------------------------------
randomHit:
        call    near    myRandom
        ; st0 = random number between 0 and 1
        fld     dword   [random_mod]
        fidivr  dword   [random_seed]
        fcomip          st1
        jc      short   .positive
.negative:                      ; st0 > prob (miss)
        mov     dword   eax, 0
        ret
.positive:                      ; st0 < prob (hit)
        mov     dword   eax, 1
        ret
; -----------------------------------------------------------------------------
; uint randomInt (uint)
; returns a pseudo-random integer between 0 and eax-1
; -----------------------------------------------------------------------------
randomInt:
        mov     dword   [randint], eax
        call    near    myRandom
        ; st0 = random number between 0 and 1
        fld     dword   [random_mod]
        fidivr  dword   [random_seed]
        ; st0 = random number between 0 and eax
        fimul   dword   [randint]
        ; randint = int(st0)
        fisttp  dword   [randint]
        mov     dword   eax, [randint]
        ret
