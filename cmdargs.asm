; AUTHOR: Connor McDermid
; DATE: 2021-09-23
; 64-bit Lab 2 "cmdargs": 
%include "Macros_CPsub64.inc"
%include "CPsub64.inc"

global	main			; global entry point for ld

section	.text
main:
	call	Crlf

	cmp	rdi, 2		; is <2 args
	jl	NoArgs		; if yes, goto NoArgs

	mov	rdx, cntmsg	; print count
	call 	WriteString
	mov	rax, rdi	; load argument count
	call	WriteInt	; write decimal integer
	call 	Crlf	

	
	mov	r8, 0		; copy reg contents so as to not clobber rdi, rsi, etc.
	mov 	r9, rdi		; argument count
	mov 	r10, rsi	; pointer to argument 0

loopnt	equ	$		; top of the loop

	mov 	rdx, [r10 + r8]	; load rdx with contents at eff. addr. r10 + r8
	call	WriteString	; program suspended for write to terminal
	call 	StrLength	; calculate length of string	
	mov	[saverax], rax	; save RAX register
	mov	rdx, spacemsg
	call	WriteString	; write a single space character
	mov	rax, [saverax]	; restore RAX
	call 	WriteInt
	call 	Crlf

	add	r8, 8		; 
	dec	r9		; one less argument
	
jnz	loopnt		; bottom of loop
	jmp	EOP		; goto exit routine

;	mov	rsi, ipbuffer	; load with address
;	mov	rbx, 2		; format of type 2
;	call	DumpMem		; dump 32 bytes at address

;	call	Crlf
;	call	Crlf


NoArgs	equ	$	
	mov	rdx, noargmsg	; post noargs message
	call	WriteString
	call	Crlf
	jmp	EOP		; jump to end of program

EOP	equ	$		; End of Program Tag
	mov	rdx, endmsg	; post EOP message
	call	WriteString	; system call
	
	call	Crlf
	call	Crlf

	Exit
section .data
cntmsg	 db 	"The count of command line arguments found is: ",00h	; message and NULL
noargmsg db	"No arguments detected.",00h	; message and NULL
endmsg	 db	"End of program.",00h	; message and NULL
spacemsg db	20h,00h
saverax	 dq	0			; save area for RAX register
