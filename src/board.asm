%include "src/lib.asm"
        
NCOLS:          equ     40
WIDTH:          equ     NCOLS+1
NROWS:          equ     12
MAXS:           equ     (NROWS-2)*(NCOLS-2)

struc           queue
.data:          resd    MAXS
.size:          resd    1
endstruc
        
section .data
score_msg:      db      'Score: ', 0
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
snake:
istruc          queue
at queue.data,  dd      WIDTH * NROWS/2 + WIDTH/2
times   MAXS-1  dd      0
at queue.size,  dd      1
iend

section .text
global update, printBoard
extern randomHit, randomInt
; -----------------------------------------------------------------------------
; (int, int) update (int, int)
; determines the next frame and updates the game board, the snake queue, and
;       the game state (win/loss/continue).
; Returns: curr_dir (eax), game_state (ebx)
; Args: curr_dir (eax), input (ebx)
; -----------------------------------------------------------------------------
update:
	; compare cur_dir with input and possibly keep the same direction
	mov	dword 	ecx, eax
	mov	dword	edx, ebx
	add	dword	ecx, edx
	cmp	dword	ecx, 0
	; keep input received
	jnz	short	.keepInputDirection
	; set input as the current direction
	mov	dword	ebx, eax
.keepInputDirection:	
	; calculate new head (esi) and update curr_dir (eax)
        mov     dword   esi, [snake+queue.data+0]
        add     dword   esi, ebx ; input
        mov     dword   eax, ebx ; curr_dir
        push    dword   eax      ; save in the stack to return later
        ; check if game ended
        cmp     byte    [board+esi], '#'
        je      	.lose
	cmp	byte	[board+esi], 'O'
	je 		.lose
        cmp     dword   [snake+queue.size], MAXS-1
        je      	.win
        ; didn't win nor lose: continue
        push    dword   0       ; game_state=0: continue
	cmp	byte	[board+esi], '*'
	jz 	short 	.ateUpdateSnakeSize
	jne	short 	.didntEatUpdateSnakeSize
.ateUpdateSnakeSize:
	;; j = ++snake.size
	inc	dword	[snake+queue.size]
	mov	dword	edx, [snake+queue.size]
	;; snake.data[j-1] = snake.data[j-2]
	mov	dword	ecx, [snake+queue.data+4*(edx-2)]
	mov	dword	[snake+queue.data+4*(edx-1)], ecx
	mov	dword	ecx, edx
	dec	dword	ecx
	jmp	short	.updateSnakeData
.didntEatUpdateSnakeSize:
	;; j = snake.size
	mov	dword	edx, [snake+queue.size]
	;; board[snake.data[j - 1]] = ' '
	mov	dword	ecx, [snake+queue.data+4*(edx-1)]
	mov	byte	[board+ecx], ' '
	mov	dword	ecx, edx
	dec	dword	ecx
	jmp	short 	.updateSnakeData
.updateSnakeData:
	;; while (j >= 1)
	cmp	dword	ecx, 0
	jz	short	.updateHead
	;; snake.data[j] = snake.data[j-1]
	mov	dword	edx, [snake+queue.data+4*(ecx-1)]
	mov	dword	[snake+queue.data+4*ecx], edx
	dec	dword	ecx
	mov	dword	edx, [snake+queue.data+4*ecx]
	mov	byte	[board+edx], 'O'
	jmp	short	.updateSnakeData
.updateHead:
	;; snake.data[0] = new_head
	mov	dword	[snake+queue.data+0], esi
	mov	byte	[board+esi], '@'
.testFruit:
        ; check if a fruit will spawn during this frame
        call    near    randomHit
        cmp     dword   eax, 1
        jne     short   .done
.placeFruit:
        ; loops until randomInt picks an empty spot
        mov     dword   eax, MAXS
        call    near    randomInt
        cmp     byte    [board+eax], ' '
        jne     short   .placeFruit
        ; draws fruit in the selected empty random spot
        mov     byte    [board+eax], '*'
        jmp     short   .done
.win:
        push    dword   +1      ; game_state=+1: win
        jmp     short   .done
.lose:
        push    dword   -1      ; game_state=-1: loss
        jmp     short   .done
.done:
        pop     dword   ebx     ; game_state
        pop     dword   eax     ; curr_dir
        ret
; -----------------------------------------------------------------------------
; void printBoard ()
; displays the current score (snake size) and frame of the game board state
; -----------------------------------------------------------------------------
printBoard:
        mov     dword   eax, score_msg
        call    near    printstr
        mov     dword   eax, [snake+queue.size]
        call    near    printuint
        call    near    printnl
        mov     dword   eax, board
        call    near    printstr
        ret
