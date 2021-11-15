; AUTHOR: Connor McDermid
; DATE: 2021-11-05
; 64-bit Lab 7 "fibonacci"
%include "Macros_CPsub64.inc"
%include "CPsub64.inc"

global	main	; global entry point export for ld

section .data
eopmsg	db	"Program terminating.",00h
prompt	db	"Please enter the quantity of fibonacci numbers you'd like: ",00h
ipbuf	times	255 db	20h 	; define buffer of whitespace
ipbufln	equ	$-ipbuffer

section .text

main:

; keep looping until user quits
loopnt	equ	$
	call	Crlf
	mov	rdx, prompt	; write user prompt
	call	WriteString

	mov	rdx, ipbuf	; address data buffer
	mov	rcx, ipbufln	; limit data
	call	ReadString	; perform keyboard read
	mov	rdx, ipbuffer	; address numeral input area
	mov	rcx, rax	; numeral count
	call	ParseInteger64	; parse signed binary from input
