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

;------------------------------------------------------
; SUBROUTINE: fpcvt
; INPUTS: One IEEE-754 encoded floating point number
; OUTPUTS: One string-encoded decimal floating point number
; A probably fairly complicated bit hack to manually convert since I can't find any
; instructions or libraries to do it for me.
fpcvt:
	; subroutine prologue
	push	rbp	; save caller base pointer
	mov	rbp, rsp; new base pointer
	sub	rsp, 2*8; allocate x local vars if needed
	push	rax
	push	rbx	; save working regs

	; subroutine body
	; fetch parameter into xmm0
	movdqu	xmm0, [rbp + 8]
	; while technically signed, our float will *always* be positive, so
	; I don't care about the sign bit
	; next, parse exponent
	; make bitmask for only the first 16 bits minus the sign bit -- 
	; 0x7FFF0000000000000000000000000000
	mov	[rbp - 8], rax	; save rax as local var
	and	rax, 0x7FFF << 28
	shr	rax, 13	; bitshift 13 to the right
	sub	rax, 1023 ; unbias exponent (double exponent bias is 1023)
	; exponent now in RAX
	mov	rbx, [rbp - 8] ; copy original from local var into RBX
	; bitmask for final 52 bits
	; 0x000FFFFFFFFFFFFF
	and	rbx, 0x0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF; rbx now contains mantissa or fractional significand
	; no bitshift needed	
	; need a test of the endianness of the mantissa
	mov	[rbp - 16], rax	; second local variable now contains exponent
	mov	rax, rbx
	call	WriteInt

	; subroutine epilogue
	pop rbx
	pop rax
	add	rsp, 2*8; deallocate x local vars
	mov	rsp, rbp
	pop	rbp
	ret
;
;-------------------------------------------------------

;-------------------------------------------------------
; SUBROUTINE: phi
; INPUTS: two integers fib(n-1) and fib(n)
; OUTPUTS: approximation of phi in XMM0
; Uses SSE registers because I can't be bothered to bit-hack my way to infinitely more accurate values of phi
; On x86-64 Unix *all* SSE registers are scratch registers -- I have no responsibility to save any of them.
phi:
	; subroutine prologue
	push	rbp	; save caller base pointer
	mov	rbp, rsp; new base pointer
	;sub	rsp, x*8; allocate x local vars if needed
	push	rax
	push	rbx

	; subroutine body
	mov	rax, [rbp + 2*8]; retrieve param 1 (fib(n-1))
	mov	rbx, [rbp + 3*8]; retrieve param 2 (fib(n))
	; convert integers to double-precision floats
	cvtsi2sd xmm0, rax; cvtsi2sd = convert signed integer to signed double
	cvtsi2sd xmm1, rbx
	; now divide them
	divsd	xmm0, xmm1 ; divide signed double
	; result now stored as double-precision floating point in xmm0
	; now move it to a general-purpose register so it can be used by the rest of the program
	; *without* clobbering the floating-pointedness
	;movq	rcx, xmm0	; move quadword
	; done

	; subroutine epilogue
	pop	rbx
	pop	rax
	;add	rsp, x*8; deallocate local vars
	mov	rsp, rbp
	pop	rbp
	ret

;--------------------------------------------------------

;--------------------------------------------------------
; SUBROUTINE: fib
; INPUTS: Quantity
; OUTPUTS: Requested numbers in RAX
fib:
	; subroutine prologue
	push	rbp	; save caller base pointer
	mov	rbp, rsp; new base pointer
	sub	rsp, 3*8; allocate 3 local vars on stack
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
	cmp	rax, 0 ; return of 0 from RAX indicates invalid input
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
		je	goldrat		; if equal, leave loop
		inc	r15		; else, increment iterator + continue
		jmp	fibloop		; loop again
	; once more for golden ratio
goldrat	equ	$
	push	r8
	call	fib
	add	rsp, 8*1; clear r8 from stack
	mov	rbx, rax
	push	r8
	call	fib
	add	rsp, 8*1
	push	rax
	push 	rbx
	call	phi
	add	rsp, 8*2
	; OK, for this I need to push an SSE register onto the stack
	; It is twice the size of a normal register
	; as such I cannot use push and pop
	; I need to do it manually
	sub	rsp, 8*2; subtract 16 bytes or 128 bits
	movdqu	dqword [rsp], xmm0
	call	fpcvt	; call floating point converter
	; pop xmm0
	add	rsp, 8*2

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



