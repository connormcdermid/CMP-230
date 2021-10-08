; AUTHOR: Connor McDermid
; DATE: 2021-09-23
; 64-bit Lab 2 "numrep": 
%include "Macros_CPsub64.inc"
%include "CPsub64.inc"

global	main			; global entry point for ld

section	.text
; attempting to write my own working procedure -- reverse engineered from provided procedure lib
writeNumbers:			; takes the number in RAX and prints it in decimal, hex, and binary
	call	Crlf
	mov	rdx, decmsg	; write decmsg
	call	WriteString
	call	Crlf
	
	call	WriteInt
	call	Crlf

	mov	rdx, hexmsg	; write hexmsg
	call	WriteString	
	call	Crlf

	call	WriteHex
	call	Crlf

	mov	rdx, binmsg	; write binmsg
	call	WriteString
	call	Crlf

	call	WriteBin
	call	Crlf
	
	ret			; MUST BE INCLUDED otherwise program continues at top of next procedure
				; in this case, causes infinite loop


main:
	call	Crlf
	mov	rdx, prompt1
	call	WriteString
	
	mov 	rdx, ipbuffer	; address the data buffer
	mov	rcx, ipbuflen	; limit data
	call	ReadString	; perform a keyboard read
	mov	rdx, ipbuffer	; address numeral input area
	mov	rcx, rax	; numeral count
	call	ParseInteger64	; convert to signed binary
	mov	[num1], rax	; store signed bin

	call	Crlf
	mov	rdx, prompt2
	call	WriteString
	
	mov 	rdx, ipbuffer	; address the data buffer
	mov	rcx, ipbuflen	; limit data
	call	ReadString	; perform a keyboard read
	mov	rdx, ipbuffer	; address numeral input area
	mov	rcx, rax	; numeral count
	call	ParseInteger64	; convert to signed binary
	mov	[num2], rax	; store signed bin

;	call	DumpRegs	; dump registers for debugging

;	mov	rsi, num1	; load with address
;	mov	rbx, 2		; format of type 2
;	call	DumpMem		; dump 32 bytes at address

	call	Crlf
	
	mov	rax, [num1]
	call	writeNumbers

	mov	rax, [num2]
	call	writeNumbers

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

term	equ	$
	mov	rdx, eopmsg
	call	WriteString
	call	Crlf
	Exit
section .data
prompt1	db 	"Please enter a signed integer between 2^63 - 1 and -2^63 - 1: ",00h	; First prompt & NULL
prompt2	db	"Please enter a second number with the same limits: ",00h	; second prompt & NULL
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
