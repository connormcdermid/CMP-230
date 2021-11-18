; AUTHOR: Connor McDermid
; DATE: 2021-11-05
; 64-bit Lab 7 "fibonacci"
%include "Macros_CPsub64.inc"
%include "CPsub64.inc"

global	main	; global entry point export for ld

section .data
eopmsg	db	"Program terminating.",00h
negmsg	db	"The number must be positive.",00h	; remember null terminators
prompt	db	"Please enter the quantity of fibonacci numbers you'd like: ",00h
ipbuf	times	255 db	20h 	; define buffer of whitespace
ipbufln	equ	$-ipbuf
invmsg	db	"Integer is not valid. Please try again."

section .text

;--------------------------------------------------------
; SUBROUTINE: fib
; INPUTS: Quantity
; OUTPUTS: Requested numbers in RAX
fib:
	; subroutine prologue
	push	rbp	; save caller base pointer
	mov	rbp, rsp; new base pointer
	sub	rsp, 3*8; allocate 2 local vars on stack
	push	rbx	; save caller regs
	push	rcx	; for use as working regs
	
	; subroutine body
	mov	rax, [rbp + 2*8]; retrieve parameter
	cmp	rax, 1		; if n = 1
	jle	return		; return from subroutine
				; else, continue
	mov	rbx, 1
	mov	rcx, 2
	push 	rax	; preserve original value of RAX
	sub	rax, rbx	; n - 1
	mov	rbx, rax	; rbx should hold n - 1 value
	pop	rax		; restore value of RAX
	sub	rax, rcx	; n - 2
	mov	rcx, rax	; rcx should hold n - 2 value
	push	rbx		; pass n - 1 to fib()
	call	fib
	pop	rbx
	mov	rbx, rax	; fib(n - 1) now in RBX
	push	rcx		; pass n - 2 to fib()
	call	fib
	pop 	rcx
	mov	rcx, rax	; fib(n - 2) now in RCX
				; yeah, yeah, I could just use RAX, but this is more readable
	
	add	rbx, rcx	; fib(n - 1) + fib(n - 2)
	mov	rax, rbx	; move result of fib function to RAX for return
	jmp	return
	
return	equ	$
	; subroutine epilogue
	pop	rcx		; restore caller regs
	pop	rbx	
	add	rsp, 3*8	; clear stack of local var allocations
	mov	rsp, rbp	; restore caller stack pointer
	pop	rbp	; restore caller base pointer
	ret	; return from subroutine with result in RAX
	
	
	
; END SUBROUTINE: fib
;--------------------------------------------------------

main:

; keep looping until user quits
loopnt	equ	$
	call	Crlf

	mov	rdx, prompt	; write user prompt
	call	WriteString
	call	Crlf

	mov	rdx, ipbuf	; address data buffer
	mov	rcx, ipbufln	; limit data
	call	ReadString	; perform keyboard read
	mov	rdx, ipbuf	; address numeral input area
	mov	rcx, rax	; numeral count
	call	ParseInteger64	; parse signed binary from input, returned in RAX
	cmp	rax, 0
	je	invalid
	jl	negnum	; causes infinite loop
	mov	r8, rax	; preserve original user input
	; indenting for ease of reading
	mov	r15, 1	; loop iterator variable
	fibloop	equ	$
		
		push	r15	; fib(R15)
		call	fib
		add	rsp, 8*1; clear R15 from stack
		; whaddaya know, fib() also returns RAX
		call	WriteInt	; print fib(n)
		call	Crlf
		cmp	r15, r8		; compare user input w/ loop iterator
		je	term		; if equal, leave loop
		inc	r15		; else, increment iterator + continue
		jmp	fibloop		; loop again

invalid	equ	$
	mov	rdx, invmsg	; write invalid message
	call	WriteString
	call	Crlf
	jmp	loopnt		; loop back to beginning of subroutine

negnum	equ	$
	mov	rdx, negmsg	; write negative numbers message
	call	WriteString
	call	Crlf
	jmp	loopnt		; loop back to beginning of subroutine

term	equ	$
	mov	rdx, eopmsg	; address message
	call	WriteString
	call	Crlf
	Exit



