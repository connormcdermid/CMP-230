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
; SUBROUTINE fibonacci
; INPUTS: Index of fibonacci sequence to retrieve
; OUTPUTS: Result in RAX
fibonacci:

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
	test	r10, r10	; set zero flag as per https://stackoverflow.com/a/54499552/7327253
	ret
; END SUBROUTINE
;-------------------------------------------------------------------
 
main:

	; calculate fibonacci number

	; calculate golden ratio


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
recurse equ	$
	call main	; sneaky recursion for looping

section .data

tabchar	db	20h,20h,20h,20h,00h	; For use in formatting output: looks really ugly without it
prompt	db 	"Please enter an index: ",00h	; First prompt & NULL
curnum	dq	00h
prevnum	dq	00h
oper	db	20h
result	dq	00h
resmsg	db	"The RESULT is: ",00h
res	dq	00h
phimsg	db	"the GOLDEN RATIO is: ",00h
phi	dq	00h
badmsg	db	"Bad integer.",00h
eopmsg	db	"Program terminating.",00h
ipbuffer times 	255 db 20h	; define buffer of spaces
ipbuflen equ	$-ipbuffer
