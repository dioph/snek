%include "src/lib.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                              SYSTEM DEFINITIONS                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
SYS_IOCTL:      equ     54
SYS_FCNTL:      equ     55
SYS_NANOSLEEP:  equ     162
  
TCGETS:         equ     0x5401
TCSETSW:        equ     0x5403

INCLR:          equ     64
IGNCR:          equ     128
ICRNL:          equ     256
IXON:           equ     1024
IXOFF:          equ     4096

ISIG:           equ     1
ICANON:         equ     2
ECHO:           equ     8

F_SETFL:        equ     4
O_NONBLOCK:     equ     2048

struc           termios
c_iflag:        resd    1
c_oflag:        resd    1
c_cflag:        resd    1
c_lflag:        resd    1
c_cc:           resb    64
endstruc

struc           timespec
tv_sec:         resd    1
tv_nsec:        resd    1
endstruc
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                             PROGRAM DEFINITIONS                             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
SAVED_TERMIOS:  equ     1
NCOLS:          equ     40
WIDTH:          equ     NCOLS+1
NROWS:          equ     12
MAXS:           equ     (NROWS-2)*(NCOLS-2)      
DELAYms:        equ     200

struc           queue
.data:          resd    MAXS
.size:          resd    1
endstruc
        
section .data
error_msg:      db      'I did a poo poo', 10, 0
go_up_cmd:      db      27, "[1A", 0
score_msg:      db      'Score: ', 0
win_msg:        db      'Congratulations! You WON!', 10, 0
lose_msg:       db      'YOU DIED', 10, 0
curr_dir:       dd      0
tty_state:      dd      0
game_state:     dd      0
        
board:
times   NCOLS   db      '#'
                db      10
%rep    NROWS-2
                db      '#'
times   NCOLS-2 db      ' '
                db      '#', 10
%endrep
times   NCOLS   db      '#'
                db      10, 0

delay:
istruc          timespec
at tv_sec,      dd      0
at tv_nsec,     dd      DELAYms * 1000000
iend

snake:
istruc          queue
at queue.data,  dd      WIDTH * NROWS/2 + WIDTH/2
times   MAXS-1  dd      0
at queue.size,  dd      1
iend

section .bss
new_tty_io:     resb    termios_size
old_tty_io:     resb    termios_size
char:           resb    1
input:          resd    1

section .text
global _start

_start:
        ; initialize the snake of size 1 in the center of the board
        mov     dword   esi, [snake+queue.data+0]
        mov     byte    [board+esi], '@'
        ; disable echoing and line buffering
        ;; get old_tty_io and save it for restoring purposes
        mov     dword   eax, SYS_IOCTL
        mov     dword   ebx, STDIN
        mov     dword   ecx, TCGETS
        mov     dword   edx, old_tty_io
        int     byte    0x80
        test    dword   eax, eax
        js      near   .error
        or      dword   [tty_state], SAVED_TERMIOS
        ;; copy old_tty_io to new_tty_io
        cld
        mov     dword   ecx, termios_size
        mov     dword   esi, old_tty_io
        mov     dword   edi, new_tty_io
        rep movsb
        ;; change new_tty_io iflags and lflags
        mov     dword   eax, [new_tty_io+c_iflag]
        and     dword   eax, (~(INCLR | IGNCR | ICRNL | IXON | IXOFF))
        mov     dword   [new_tty_io+c_iflag], eax
        mov     dword   eax, [new_tty_io+c_lflag]
        and     dword   eax, (~(ECHO | ICANON | ISIG))
        mov     dword   [new_tty_io+c_lflag], eax
        ;; set new_tty_io
        mov     dword   eax, SYS_IOCTL
        mov     dword   ebx, STDIN
        mov     dword   ecx, TCSETSW
        mov     dword   edx, new_tty_io
        int     byte    0x80
        test    dword   eax, eax
        js      near   .error
        ; print board for the first time
        call    near    printBoard
.gameLoop:
        ; set stdin as non-blocking
        mov     dword   eax, SYS_FCNTL
        mov     dword   ebx, STDIN
        mov     dword   ecx, F_SETFL
        mov     dword   edx, O_NONBLOCK
        int     byte    0x80
        ; read single char
        mov     dword   eax, SYS_READ
        mov     dword   ebx, STDIN
        mov     dword   ecx, char
        mov     dword   edx, 1
        int     byte    0x80
        ; determine input from char
        cmp     dword   eax, 1
        jne     short   .invalid
        cmp     byte    [char], 'w'
        je      short   .moveW
        cmp     byte    [char], 'a'
        je      short   .moveA
        cmp     byte    [char], 's'
        je      short   .moveS
        cmp     byte    [char], 'd'
        je      short   .moveD
.invalid:                       ; if no input, keep going in the same direction
        mov     dword   eax, [curr_dir]
        mov     dword   [input], eax
        jmp     short   .inputDone
.moveW:                         ; up
        mov     dword   [input], -WIDTH
        jmp     short   .inputDone
.moveA:                         ; left
        mov     dword   [input], -1
        jmp     short   .inputDone
.moveS:                         ; down
        mov     dword   [input], +WIDTH
        jmp     short   .inputDone
.moveD:                         ; right
        mov     dword   [input], +1
        jmp     short   .inputDone
.inputDone:
        ; un-unblock stdin
        mov     dword   eax, SYS_FCNTL
        mov     dword   ebx, STDIN
        mov     dword   ecx, F_SETFL
        mov     dword   edx, 0
        int     byte    0x80
        ; while(char != <ESC>)
        cmp     byte    [char], 0x1b
        je      short   .end
        ; clear screen (move cursor up NROWS + 1)
        mov     dword   ecx, NROWS+1
.cursorUp:
        mov     dword   eax, go_up_cmd
        call    near    printstr
        loop            .cursorUp
        ; print updated board
        call    near    update
        call    near    printBoard
        ; check if game ended
        cmp     dword   [game_state], -1
        je      near    .lose
        cmp     dword   [game_state], +1
        je      near    .win
        ; chotto matte
        mov     dword   eax, SYS_NANOSLEEP
        mov     dword   ebx, delay
        mov     dword   ecx, delay
        int     byte    0x80
        ; keep going
        jmp     near    .gameLoop
.lose:
        mov     dword   eax, lose_msg
        call    near    printstr
        jmp     short   .end
.win:
        mov     dword   eax, win_msg
        call    near    printstr
        jmp     short   .end
.error:
        ; if sth goes wrong, restore termios, print error msg and exit 1
        call    near    restore
        mov     dword   eax, error_msg
        call    near    printstr
        mov     dword   eax, SYS_EXIT
        mov     dword   ebx, 1
        int     byte    0x80
.end:
        ; if nothing goes wrong, restore termios and exit 0
        call    near    restore
        mov     dword   eax, SYS_EXIT
        mov     dword   ebx, 0
        int     byte    0x80

restore:
        ; check if managed to get old_tty_io
        test    dword   [tty_state], SAVED_TERMIOS
        jz      short   .no_termios
        ; set old_tty_io
        mov     dword   eax, SYS_IOCTL
        mov     dword   ebx, STDIN
        mov     dword   ecx, TCSETSW
        mov     dword   edx, [old_tty_io]
        int     byte    0x80
.no_termios:
        ret


update:
        ; calculate new head and update curr_dir
        mov     dword   esi, [snake+queue.data+0]
        mov     dword   ebx, [input]
        add     dword   esi, ebx
        mov     dword   [curr_dir], ebx
        ; check if game ended and update board
        cmp     byte    [board+esi], '#'
        je      short   .lose
        cmp     dword   [snake+queue.size], MAXS-1
        je      short   .win
        mov     byte    [board+esi], '@'
        mov     dword   edi, [snake+queue.data+0]
        mov     byte    [board+edi], 'O'
        ; update snake data
        mov     dword   [snake+queue.data+0], esi
        ; update snake size
        inc     dword   [snake+queue.size]
        ret
.win:
        mov     dword   [game_state], +1
        ret
.lose:
        mov     dword   [game_state], -1
        ret

        
printBoard:
        mov     dword   eax, score_msg
        call    near    printstr
        mov     dword   eax, [snake+queue.size]
        call    near    printuint
        call    near    printnl
        mov     dword   eax, board
        call    near    printstr
        ret
