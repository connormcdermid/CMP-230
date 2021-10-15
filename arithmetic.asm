; AUTHOR: Connor McDermid
; DATE: 2021-09-23
; 64-bit Lab 2 "arithmetic": 
%include "Macros_CPsub64.inc"
%include "CPsub64.inc"

global	main			; global entry point for ld

section	.text
; attempting to write my own working procedure -- reverse engineered from provided procedure lib
tab:	; prints a tab character -- double checked mnemonics list to ensure there's no mnemonic named "tab"
	SaveRegs		; don't clobber registers

	mov	rdx, tabchar
	call	WriteString

	RestoreRegs
	ret


main:
	mov	r8, 4		; r8 will be loop iterator variable

	call	Crlf
	mov	rdx, prompt1	; prompt user for number 1
	call	WriteString
	
	mov 	rdx, ipbuffer	; address the data buffer
	mov	rcx, ipbuflen	; limit data
	call	ReadString	; perform a keyboard read
	mov	rdx, ipbuffer	; address numeral input area
	mov	rcx, rax	; numeral count
	call	ParseInteger64	; convert to signed binary
	mov	[num1], rax	; store signed bin

	call	Crlf
	mov	rdx, prompt2	; prompt user for operator
	call	WriteString
	
	mov	rdx, ipbuffer
	mov	rcx, ipbuflen
	call	ReadString
	
	mov	dl, [ipbuffer]	; store only the first byte of rdx
	mov	[oper], dl	; store *that* in memory
	

	call	Crlf
	mov	rdx, prompt3	; prompt user for number 2
	call	WriteString
	
	mov 	rdx, ipbuffer	; address the data buffer
	mov	rcx, ipbuflen	; limit data
	call	ReadString	; perform a keyboard read
	mov	rdx, ipbuffer	; address numeral input area
	mov	rcx, rax	; numeral count
	call	ParseInteger64	; convert to signed binary
	mov	[num2], rax	; store signed bin

	call	Crlf
	
	mov	rax, [num1]	; load operand 1
	mov	rbx, [num2]	; load operand 2
	mov	dl, [oper]	; load operator

	cmp	dl, "+"
	je	myAdd
	cmp	dl, "-"
	je	mySub
	cmp	dl, "*"
	je	myMult
	cmp	dl, "/"
	je	myDiv
	jmp	err		; default, invalid operator

postres	equ	$
	mov	rdx, resmsg	; post resmsg
	call	WriteString
	mov	rax, [result]	; load register with result
	call	WriteInt
	call	Crlf
	mov	rcx, [rem]
	cmp	rcx, 0
	jz	term		; if no remainder, jump to end
	mov	rdx, remmsg	; if remainder, print it
	call	WriteString
	mov	rax, rcx	; remainder's already in rcx
	call	WriteInt
	call	Crlf
	jmp	term

err	equ	$
	mov	rdx, errmsg	; print error message
	call	WriteString
	call	Crlf
	jmp	term		; terminate program

myAdd	equ	$
	add	rax, rbx	; add loaded registers
	mov	[result], rax	; store sum
	mov	r10, 0
	mov	[rem], r10	; make sure remainder is 0
	jmp	postres

mySub	equ	$
	sub	rax, rbx	; add loaded registers
	mov	[result], rax	; store sum
	mov	r10, 0
	mov	[rem], r10	; make sure remainder is 0
	jmp	postres

myMult	equ	$	; outputs in RDX:RAX
	cqo	; perpetuate RAX into RDX
	call	DumpRegs
	imul	rbx	; rax, rbx already loaded with operands
;	mov	[multbuf], rdx
	mov	[result], rax
	;	add high-order bits 
	mov	r10, 0
	mov	[rem], r10
	call	DumpRegs
	jmp	postres

myDiv	equ	$
	cqo	; perpetuate RAX into RDX
	call	DumpRegs
	idiv	rbx	; RAX, RBX already loaded with operands
	mov	[rem], rdx
	mov	[result], rax
	jmp	postres

term	equ	$
	mov	rdx, eopmsg
	call	WriteString
	call	Crlf
	Exit

section .data

tabchar	db	20h,20h,20h,20h,00h	; For use in formatting output: looks really ugly without it
prompt1	db 	"Please enter the first number: ",00h	; First prompt & NULL
prompt2	db	"Please enter the operator: ",00h	; second prompt & NULL
prompt3	db	"Please enter the second number: ",00h	; third prompt & NULL
num1	dq	00h
num2	dq	00h
oper	db	20h
result	dq	00h
rem 	db	00h
resmsg	db	"The RESULT is: ",00h
remmsg	db	"the REMAINDER is: ",00h
errmsg	db	"Invalid operator.",00h
eopmsg	db	"Program terminating.",00h
ipbuffer times 	255 db 20h	; define buffer of spaces
ipbuflen equ	$-ipbuffer
multbuf	dq	00h	; multiplication result buffer
