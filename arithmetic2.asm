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

;---------------------------------------------------
; SUBROUTINE getOperand
; INPUTS: 
; OUTPUTS: Operand in RAX
; WARNING: CLOBBERS RDX, RCX
getOperand:
	
	mov	rdx, prompt1	; prompt user for number 1
	call	WriteString
	
	mov 	rdx, ipbuffer	; address the data buffer
	mov	rcx, ipbuflen	; limit data
	call	ReadString	; perform a keyboard read
	mov	rdx, ipbuffer	; address numeral input area
	mov	rcx, rax	; numeral count
	call	sanitise
	call	ParseInteger64	; convert to signed binary
	ret
; END SUBROUTINE
;------------------------------------------------------

;------------------------------------------------------
; SUBROUTINE sanitise
; INPUTS: characters read in RAX
; OUTPUTS: Error code in RBX: 0 indicates normal operation, 1 indicates error
; WARNING: CLOBBERS REGISTERS
sanitise:
	xor	rbx, rbx	; set error code 0
	mov	r10, ipbuffer	; point to initial character
	mov	r9, rax		; count of characters read
	dec	r9		; exclude NULL terminator
	xor	r8, r8		; cursor set to 0
optest	equ	$		; top of loop
	mov	al, [r10 + r8]	; eff. addr. of examined byte
	call	IsDigit
	jnz	badOp		; digit is bad
	inc	r8		; digit is good
	dec	r9		; count--;
	jnz	optest		; if still characters remaining
	jmp	goodOp
badOp	equ	$
	call	checkX		; first, make sure user isn't trying to exit
	jz	term
	mov	rdx, badmsg
	call	WriteString
	call	Crlf
	mov	rbx, 1		; set error code 1
	jmp	getReturn
goodOp	equ	$
	mov	rdx, ipbuffer
	mov	rcx, rax
	call	ParseInteger64
	jmp	getReturn
getReturn equ	$
	ret
	
; END SUBROUTINE
;-----------------------------------------------------------------

;-----------------------------------------------------------------
; SUBROUTINE checkX
; Check if user wants to exit the program
; INPUTS: User input in ipbuffer
; OUTPUTS: Sets ZF to 1 if user wants to exit
; CLOBBERS: RAX, r9, r10
checkX:
	mov	r10, [ipbuffer]
;	mov	al, [r10]	; only checking first byte for q
	mov	r9b, "q"
	cmp	r10b, r9b		; checking to see if it's q, comparing low byte of r10
	je	isq
	jne	isntq
isq	equ	$
	cmp	rax, rax	; set zero flag as per https://stackoverflow.com/a/54499552/7327253
	ret 
isntq	equ	$
	cmp	r10b, 1Bh	; check if esc
	je	isesc		; if esc, go to isesc
	test	r10, r10	; set zero flag as per https://stackoverflow.com/a/54499552/7327253
	ret
isesc	equ 	$
	cmp	rax, rax	; set zero flag
	ret
; END SUBROUTINE
;-------------------------------------------------------------------
 
main:
;	mov	r8, 4		; r8 will be loop iterator variable
	call	Crlf
	mov	rdx, initmsg	; initialisation message
	call	WriteString

	call	Crlf
	call	getOperand
	cmp	rbx, 0		; is all clean?
	jg	err
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
;	mov	rdx, prompt3	; prompt user for number 2
;	call	WriteString
	
;	mov 	rdx, ipbuffer	; address the data buffer
;	mov	rcx, ipbuflen	; limit data
;	call	ReadString	; perform a keyboard read
;	mov	rdx, ipbuffer	; address numeral input area
;	mov	rcx, rax	; numeral count
;	call	ParseInteger64	; convert to signed binary
	call	getOperand
	cmp	rbx, 0
	jg	err
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
	jz	recurse		; if no remainder, jump to end
	mov	rdx, remmsg	; if remainder, print it
	call	WriteString
	mov	rax, rcx	; remainder's already in rcx
	call	WriteInt
	call	Crlf
	jmp	recurse

err	equ	$
	mov	rdx, errmsg	; print error message
	call	WriteString
	call	Crlf
	jmp	recurse

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
	mov	r15, 0
	cmp	rbx, r15
	je	dbz
	cqo	; perpetuate RAX into RDX
	idiv	rbx	; RAX, RBX already loaded with operands
	mov	[rem], rdx
	mov	[result], rax
	jmp	postres

term	equ	$
	mov	rdx, eopmsg
	call	WriteString
	call	Crlf
	Exit
recurse equ	$
	call main	; sneaky recursion for looping

dbz	equ	$
	mov	rdx, dbzerr
	call	WriteString
	jmp	recurse

section .data

initmsg db	"Enter any integer, an operator, and a second integer. Enter 'q' at any time to quit.",00h
tabchar	db	20h,20h,20h,20h,00h	; For use in formatting output: looks really ugly without it
prompt1	db 	"Please enter an operand: ",00h	; First prompt & NULL
prompt2	db	"Please enter the operator: ",00h	; second prompt & NULL
;prompt3	db	"Please enter the second number: ",00h	; third prompt & NULL
num1	dq	00h
num2	dq	00h
oper	db	20h
result	dq	00h
rem 	db	00h
resmsg	db	"The RESULT is: ",00h
remmsg	db	"the REMAINDER is: ",00h
errmsg	db	"Invalid entry. Press q to quit.",00h
badmsg	db	"Bad integer.",00h
eopmsg	db	"Program terminating.",00h
dbzerr	db	"Division by zero exception.",00h
ipbuffer times 	255 db 20h	; define buffer of spaces
ipbuflen equ	$-ipbuffer
multbuf	dq	00h	; multiplication result buffer
