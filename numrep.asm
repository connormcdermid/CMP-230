; AUTHOR: Connor McDermid
; DATE: 2021-09-23
; 64-bit Lab 2 "numrep": 
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

writeNumbers:			; takes the number in RAX and prints it in decimal, hex, and binary
	SaveRegs		; don't clobber registers

	call	Crlf
	call	tab
	mov	rdx, decmsg	; write decmsg
	call	WriteString
	call	Crlf
	
	call	tab
	call	tab
	call	WriteInt	; write decimal representation
	call	Crlf

	call	tab
	mov	rdx, hexmsg	; write hexmsg
	call	WriteString	
	call	Crlf

	call	tab
	call	tab
	call	WriteHex	; write hexadecimal representation
	call	Crlf

	call	tab
	mov	rdx, binmsg	; write binmsg
	call	WriteString
	call	Crlf
	
	call	tab
	call	tab
	call	WriteBin	; write binary representation
	call	Crlf

	RestoreRegs
	
	ret			; MUST BE INCLUDED otherwise program continues at top of next procedure
				; in this case, causes infinite loop

main:
	mov	r8, 4		; r8 will be loop iterator variable

loopnt	equ	$		; top of loop
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
	mov	rdx, prompt2	; prompt user for number 2
	call	WriteString
	
	mov 	rdx, ipbuffer	; address the data buffer
	mov	rcx, ipbuflen	; limit data
	call	ReadString	; perform a keyboard read
	mov	rdx, ipbuffer	; address numeral input area
	mov	rcx, rax	; numeral count
	call	ParseInteger64	; convert to signed binary
	mov	[num2], rax	; store signed bin

	call	Crlf

	mov	rdx, n1msg
	call	WriteString
	call	Crlf
	mov	rax, [num1]
	call	writeNumbers	; call to writeNumbers to print all representations
	call	Crlf

	mov	rdx, n2msg
	call	WriteString
	call	Crlf
	mov	rax, [num2]
	call	writeNumbers
	call	Crlf

	; now, print OR, AND, and XOR
	
	mov	rax, [num1]
	call	WriteInt
	mov	rdx, ormsg
	call	WriteString
	mov	rax, [num2]
	call	WriteInt
	call	Crlf

	mov	rax, [num1]
	mov	rbx, [num2]
	or	rax, rbx	; num1 OR num2, result in RAX
	call	writeNumbers
	call	Crlf


	mov	rax, [num1]
	call	WriteInt
	mov	rdx, andmsg
	call	WriteString
	mov	rax, [num2]
	call	WriteInt
	call	Crlf

	mov	rax, [num1]
	mov	rbx, [num2]
	and	rax, rbx	; num1 AND num2, result in RAX
	call	writeNumbers
	call	Crlf

	mov	rax, [num1]
	call	WriteInt
	mov	rdx, xormsg
	call	WriteString
	mov	rax, [num2]
	call	WriteInt
	call	Crlf

	mov	rax, [num1]
	mov	rbx, [num2]
	xor	rax, rbx	; num1 XOR num2, result in RAX
	call	writeNumbers
	call	Crlf
	dec	r8

	jnz	loopnt		; if r8 is not 0, loop

	jmp	term		; program finished -- terminate

term	equ	$
	mov	rdx, eopmsg
	call	WriteString
	call	Crlf
	Exit
section .data

tabchar	db	20h,20h,20h,20h,00h	; For use in formatting output: looks really ugly without it
prompt1	db 	"Please enter a signed integer between 2^63 - 1 and -2^63 - 1: ",00h	; First prompt & NULL
prompt2	db	"Please enter a second number with the same limits: ",00h	; second prompt & NULL
n1msg	db	"FIRST NUMBER: ",00h
n2msg	db	"SECOND NUMBER: ",00h
decmsg	db	"DECIMAL: ",00h
hexmsg	db	"HEXADECIMAL: ",00h
binmsg	db	"BINARY: ",00h
ormsg 	db	" OR ",00h
andmsg	db	" AND ",00h
xormsg	db	" XOR ",00h
eopmsg	db	"Program terminating.",00h
ipbuffer times 	255 db 20h			; define buffer of spaces
ipbuflen equ	$-ipbuffer
num1	dq	00h	; first number
num2	dq	00h	; second number
