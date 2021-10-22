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
	jnz	term
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
; BUGS: Causes a segmentation fault.
checkX:
	SaveRegs		; no need to clobber registers
	mov	r10, [ipbuffer]
	mov	al, [r10]	; only checking first byte for q
	mov	r9, "q"
	cmp	al, r9		; checking to see if it's q
	je	isq
	jne	isntq
isq	equ	$
	cmp	rax, rax	; set zero flag as per https://stackoverflow.com/a/54499552/7327253
	RestoreRegs
	ret 
isntq	equ	$
	test	r10, r10	; set zero flag as per https://stackoverflow.com/a/54499552/7327253
	RestoreRegs
	ret
; END SUBROUTINE
;-------------------------------------------------------------------
 
main:
;	mov	r8, 4		; r8 will be loop iterator variable

	call	Crlf
	call	getOperand
	cmp	rbx, 0		; is all clean?
	jg	term
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
	jg	term
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
errmsg	db	"Invalid operator.",00h
badmsg	db	"Bad integer.",00h
eopmsg	db	"Program terminating.",00h
ipbuffer times 	255 db 20h	; define buffer of spaces
ipbuflen equ	$-ipbuffer
multbuf	dq	00h	; multiplication result buffer
