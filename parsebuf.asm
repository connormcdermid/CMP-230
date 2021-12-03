; AUTHOR: Connor McDermid
; DATE:2021-09-23
; 640bit Lab 8 "parsebuf"
%include "Macros_CPsub64.inc"
%include "CPsub64.inc"

global 	main			; global entry point for ld

section .data

prompt 	db	"Please enter a sentence: ",0x00	; prompt and NULL
ipbuf	times	255 db 0x20		; input buffer, populated with spaces
ipbufl	equ	$-ipbuffer		; input buffer length, calculated with memory addresses
token	times 	255 db 0x00		; token buffer, populated with NULL to prevent print mangling
tokmsg	db	"Token: ",0x00		; token message & NULL
tokenpos resb	8			; reserve 8 bytes for tokenpos
lenmsg	db	" of length "0x00	; token length message & NULL
toklen	db	0x0			; reserve space for token length

section .text
;-------------------------------------------------------------------------------------------------------
; TOKENPOSLEN
; INPUTS: cursor index
; OUTPUTS: index in RAX, length in RCX
; DESCRIPTION: Locates and finds the length of a token in a string
tokenposlen:
	; subroutine prologue
	push	rbp	; save caller base pointer
	mov	rbp, rsp; new base pointer
	;sub	rsp, x*8; allocate local vars
	push	rdx	; save caller regs
	; I use RAX and RCX as working regs, but they contain return values so I don't save them	

	; subroutine body
	mov	rdx, [rbp + 16] ; retrieve parameter 1 -- cursor position
	mov	rax, rdx	; move cursor position into RAX
	xor	rcx, rcx	; set rcx to 0

	iter	equ	$	; top of consumption loop
		inc	rdx		; increment cursor position
		cmp	[rdx], 0x00	; if character is null-terminator
		je	return		; then return from subroutine
		cmp	[rdx], 0x20	; all chars with value of 0x20 or less are whitespace
		jle	iter		; if the character is whitespace, loop again
		mov	rax, rdx	; else, save index of token
		jmp	tokl		; and goto tokl
	
	tokl	equ	$	; token located
		inc	rcx
		inc	rdx	; next character
		cmp	[rdx], 0x20	; all chars with value of 0x20 or less are whitespace
		jle	return	; if character is whitespace, the token has ended
		jmp	tokl	; else, loop again

	return	equ	$	; return from subroutine
	; subroutine epilogue
	pop	rdx	; restore caller regs
	;add	rsp, x*8; deallocate local vars
	mov	rsp, rbp; restore caller stack pointer
	pop	rbp	; restore caller base pointer
	ret		; return from subroutine with result in RAX
; END TOKENPOSLEN
;--------------------------------------------------------------------------------------------------------

main:
	call	Crlf	; newline
	mov	rdx, prompt	; load message address
	call	WriteString	; program suspended for write to terminal
	mov	rdx, ipbuf	; address data buffer
	mov	rcx, ipbufl	; limit data
	call	ReadString	; program suspended for keyboard read
	mov	rdx, ipbuf	; address data buffer
	mov	byte [rdx + rax], 0x0; ensure string is null-terminated
	mov	r11, rdx	; copy data buffer pointer to r11
	

loopnt	equ	$		; r11 is loop iterator/cursor
	mov	rdx, r11	
	push	rdx		; push rdx onto stack as parameter
	call	tokenposlen	; call tokenposlen -- outputs in RAX, RCX
	cmp	rcx, 0x0	; if rcx is zero
	je	term		; then terminate
	mov	[tokenpos], rax ; else, store token position
	mov	[tokenlen], rcx	; and store token length
	mov	r11, rax	; update cursor position: put cursor at start of token found
	add	r11, rcx	; update cursor position part 2 electric boogaloo: put cursor past located token
	inc	r11		; update cursor position part 3: char after token must be whitespace, so consume
	mov	r8, rax		; source address
	mov	r9, token	; target address
	mov	r10, rcx	; length of move
	call	Movcl		; perform token move of r10 characters from [r8] to [r9]
	mov	rdx, tokmsg	; address token message -- NOTE: CLOBBERS RDX
	call	WriteString	; program suspended for write to terminal
	mov	rdx, token	; address token proper
	call	WriteString	; program suspended for write to terminal
	mov	rdx, lenmgs	; address length message
	call	WriteString	; program suspended for write to terminal
	mov	rax, [toklen] ; copy token length to RAX -- NOTE: CLOBBERS RAX
	call	WriteInt	; program suspended for write to terminal
	call	Crlf		; program suspended for write to terminal
	jmp	loopnt		; EOL not reached, repeat

term	equ	$
	mov	rdx, termsg	; address termination message
	call	WriteString	; program suspended for write to terminal
	call	Crlf		; program suspended for write to terminal
	EXIT
