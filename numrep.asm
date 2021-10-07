; AUTHOR: Connor McDermid
; DATE: 2021-09-23
; 64-bit Lab 2 "promptech": 
%include "Macros_CPsub64.inc"
%include "CPsub64.inc"

global	main			; global entry point for ld

section	.text
main:
	call	Crlf
	mov	rdx, message
	call	WriteString
	
	mov 	rdx, ipbuffer	; address the data buffer
	mov	rcx, ipbuflen	; limit data
	call	ReadString	; perform a keyboard read

	mov	rsi, ipbuffer	; load with address
	mov	rbx, 2		; format of type 2
	call	DumpMem		; dump 32 bytes at address

	call	Crlf
	call	Crlf
	
	mov	rdx, response	; load rdx with message
	call	WriteString	; system call
	mov	rdx, ipbuffer	; load ipbuffer for printing
	call	WriteString	; system call	
	call	Crlf
	call	Crlf

	Exit
section .data
message	db 	"Please enter some data:  ",00h	; message and NULL
ipbuffer times 	255 db 20h			; define buffer of spaces
ipbuflen equ	$-ipbuffer
response db	"ECHO: ",00h	; message for echo response
