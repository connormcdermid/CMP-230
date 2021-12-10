; AUTHOR: Connor McDermid
; Date: 2021-12-09
; 64-bit Lab x "fileread":
%include "Macros_CPsub64.inc"
%include "CPsub64.inc"

global	main			; global entry point for ld

section .data
EOFmsg	db	"End of file.",0x00; EOF message & NULL
fnferr	db	"Error -- file not found.",0x00; EOF message & NULL
noarg	db	"Progam usage: fileread <file>",0x00; Help message & NULL
EOPmsg	db	"Program terminating.",0x00; EOP message & NULL
ipfile	times 255 db 0x00; file name
ipfilehandle	dq 	0; file handler
ipbuffer	times 255 db 0x00; input buffer
ipbuflen	equ	$-ipbuffer	; calculate size of ipbuffer

section .text

main:
	call	Crlf	; newline, suspended for write
	
	cmp	rdi, 2	; is 2 args?
	jl	noArgs	; if fewer, goto NoArgs
	; if greater, don't care, I ignore all but argument 1
	mov	rdx, [rsi + 8]	; copy first argument to RDX
	call	StrLength	; find length of file name
	mov	r8, rdx		; address of source
	mov	r9, ipfile	; address of target
	mov	r10, rax	; length of move
	call	Mvcl		; perform data move
	mov	byte [r9 + r10], 0x00	; append with null-terminator
	mov	rdi, ipfile	; file name
	mov	rsi, 0		; set file permissions to READ-ONLY
	call	FileOpen	; locate and read file
	cmp	rax, 0		; does file exist?
	jl	fnf		; if neg, file does not exist, goto fnf
	mov	[ipfilehandle], rax; else, file handler has been returned
	
readRec	equ	$		; top of readRec loop
	mov	rdi, [ipfilehandle]; load file handler
	mov	rdx, ipbuffer	; load address of input buffer
	call	FileRead	; read record
	cmp	rax, 0		; check for EOF
	je	term		; if so, end program
	mov	rdx, ipbuffer	; else, print record -- address buffer
	call	WriteString	; program suspended for write to terminal
	call	Crlf		; program suspended for write to terminal
	mov	rax, ipbuffer	; address buffer
	mov	rcx, ipbuflen	; length of buffer
	call	ClearBuffer	; purge buffer, write with zeros
	jmp	readRec		; goto top, read the record again

noArgs	equ	$
	mov	rdx, noarg; load noargs message address
	call	WriteString	; program suspended for write to terminal
	call	Crlf		; newline
	jmp	term

fnf	equ	$
	mov	rdx, fnferr	; load message address
	call	WriteString	; program suspended for write to terminal
	jmp	term		; goto end

EOF	equ	$
	mov	rdi, [ipfilehandle]; load file handle
	call	FileClose	; close file
	jmp	term		; goto end

term	equ	$
	mov	rdx, EOPmsg	; load EOP message address
	call	WriteString	; program suspended for write to terminal
	call	Crlf		; newline
	Exit
