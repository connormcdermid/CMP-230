;-----------------------------------------------------------------------------
; CPsub64 Link Library Source Code for Fundamental Assembly Programming 
;
; Requires: 64-bit NASM Assembler 
; Author:   Cullen Programming
; Copyright (c) 2011, 2019
;  
; Updates and New routines for NASM:
; 09/12/14 GJC Modify all for 64-bit architecture.
; 12/01/14 GJC Additional routines such as MVCL.
; 10/21/17 GJC Update doc and correct ParseInteger64
; 12/30/17 GJC Update doc
; 01/31/19 GJC Update doc
; 10/04/20 GJC Update doc and alignments
; 01/25/21 GJC Correct a register reference.  More realignment
; 02/06/21 GJC Add routines ShowCC and DumpEflags, correct ParseDecimal64

;--------------------------- MACROS ------------------------------------------
%include "Macros_CPsub64.inc"
;-------------------------------------------------------------

%assign  MAX_DIGITS 80
%define  ESC 27        		; escape code

segment 	.data		; initialized data
InitFlag DB	 0		; initialization flag
xtable   db	 "0123456789ABCDEF"  ;hex translate table

segment 	.bss		; uninitialized data
bytesWritten:  	resd 1     	; number of bytes written
eflags:  	resd 1
digitBuffer: 	resb MAX_DIGITS + 1
timeSetting:
    istruc timespec
	at tv_sec, resd 1 
	at tv_nsec, resd 1
    iend

buffer 		resb 512
%assign		bufferMax $-buffer
bytesRead 	resd 1
bufferCnt 	resd 1
 
segment 	.text
; --------------------------------------------------------
; make the functions global as the shared library functions
; --------------------------------------------------------


;--------------PROCEDURES and FUNCTIONS ----------------------------------------
global Crlf:function, ClearBuffer:function, DumpMem:function, DumpCC:function, DumpEflags:function, DumpRegs:function, FileClose:function, FileRead:function, FileWrite:function, FileOpen:function, IsDigit:function, Mvcl:functio,  ParseDecimal64:function,  ParseInteger64:function, OpenFile:function, ReadChar:function, ReadDec:function, ReadHex:function, ReadInt:function, ReadKey:function, ReadString:function, ReadStr:function, Str_compare:function, Str_copy:function, StrLength:function, Str_length:function, Str_trim:function, Str_ucase:function, WriteBin:function, WriteBinB:function, WriteChar:function, WriteDec:function, WriteHex:function, WriteHexB:function, WriteInt:function, WriteString:function
;----------------------------------------------------------


;-----------------------------------------------------------------------------
Crlf:
;
; Writes a carriage return/linefeed sequence (0Dh,0Ah) to standard output.
;
; Receives: nothing
;
; Returns: nothing
;-----------------------------------------------------------------------------
	mWrite  {0Dh,0Ah}  ; invoke a macro to write CRLF
	ret
;--------------- End of Crlf -------------------------


;----------------------------------------------------------------------------
IsDigit:
;
; Determines whether the character in AL is a valid decimal digit.
;
; Receives: AL = character
;
; Returns: ZF = 1 if AL contains a valid decimal
;          digit; otherwise, ZF = 0.
;-----------------------------------------------------------------------------
	 cmp   al, '0'	  ; if low then return				
	 jb    .ID1
	 cmp   al, '9'	  ; if high then return
	 ja    .ID1
	 test  ax, 0      ; else set ZF = 1
.ID1: 
	 ret
;--------------- End of IsDigit --------------------


;-----------------------------------------------------------------------------
DumpMem:
;
; Writes a range of 16 or 32 bytes of memory to standard output
; in hexadecimal.
;
; Receives: RSI = memory byte starting address
;           RBX = format (1=byte with spaces, 2=no spaces between bytes)
;
; Returns:  nothing
;-----------------------------------------------------------------------------
segment .data
oneSpace:   db ' ',0
dumpHeader: db 13,10,"Dump of offset: ",0
dashLine2:  db "-0-1-------5--------10--------15--------20--------25--------30--",13,10,0
dashLine1:  db "-0--1--2--3--4--5--6--7--8--9-10-11-12-13-14-15-",13,10,0

segment .text
	enter  64, 0 
	SaveRegs		; Save General Purpose Registers
	mov   rdx, dumpHeader   ; write dump header
	call  WriteString
	mov   rax, rsi		; get memory offset to dump
	call  WriteHex		; convert to hex
	call  Crlf		; new line
        cmp   rbx, 2            ; format? 
        je    .FMT2		; 
.FMT1: 
        mov   rdx, dashLine1
        mov   rcx, 16
        jmp   .L0
.FMT2:
        mov   rcx, 32
        mov   rdx, dashLine2
        jmp   .L0
.L0:
	call  WriteString
	mov   qword [rbp - 16], 0
	mov   qword [rbp - 8], rbx
	cmp   rbx, 2
	je    .L1
	jmp   .L2
.L1:
	mov   al, byte [rsi]
	call  HexByte
 	inc   qword [rbp - 16]
	inc   rsi
	mov   dx, 0
	mov   ax, word [rbp - 8]
	mov   bx, 16
	div   bx
	cmp   dx, 0
	jne   .L1B
	call  Crlf
.L1B:
	Loop  .L1
	jmp   .L4
.L2:
	mov   al, byte [rsi]
	call  HexByte
 	inc   qword [rbp - 16]
	mWriteSpace 1
	inc   rsi
	mov   dx, 0
	mov   ax, word [rbp - 8]
	mov   bx, 16
	div   bx
	cmp   dx, 0
	jne   .L2B
	call  Crlf
.L2B:
	Loop  .L2
	jmp   .L4
.L4:
	call  Crlf
	RestoreRegs		; restore register contents
	leave         		; flush stack space        
	ret
;--------------- End of DumpMem -------------------------


;-----------------------------------------------------------------------------
ClearBuffer:
;
; Clear buffer to NULLs for a given length, one byte at a time.
;
; Receives: RAX = address of the buffer
;	    RCX = length of buffer
;           
; Returns:  Nothing;
;-----------------------------------------------------------------------------
segment .data

segment .text
	push	rax 
	push	rcx
.Loop:	
	cmp	rcx, 1		; end of buffer?
	jl	.ClrExit	; 
	mov	byte [rax], 00h	; move null to buffer
	inc	rax		; increment address
	dec	rcx		; decrement count
	jmp	.Loop		; loop back baby
.ClrExit:	
	pop	rcx
	pop	rax
	ret
;--------------- End of ClearBuffer ---------------------


;-----------------------------------------------------------------------------
Mvcl:
;
; Move characters from source address to target address
; for a given length, one byte at a time.
;
; Receives: R8  -- source address
;	    R9  -- target address
;           R10 -- length (number of bytes to move)
;
; Returns:  RAX -- count of bytes moved. 
;-----------------------------------------------------------------------------
segment .data

segment .text
	push	rcx
	xor	rcx, rcx	; zero out
	xor	rax, rax	; zero out
.Loop:	
	mov	al, byte [r8 + rcx]  ; move 1 byte from source to temp
	mov	[r9 + rcx], al	; move temp to target
	inc	rcx		; increment for displacement
	cmp	r10, rcx	; reached count?
	je	.Done
	jmp	.Loop		; loop back baby
.Done:	
	mov	rax, rcx 	; return count
	pop	rcx
	ret
;--------------- End of Mvcl ---------------------


;-----------------------------------------------------------------------------
DumpCC:
;
; Displays portions of eflags known as Condition Codes
; 
; Note: All register contents are preserved.
;
; Receives: nothing.
;
; Returns: nothing.
;
;-----------------------------------------------------------------------------
segment .data

segment .text
	push 	rax		; save reg
	pushfq			; push extended flags
	pushfq			; push flags again, and
	pop  	qword [eflags]	; save them in a variable

; Show the flags (using the eflags variable). The integer parameter indicates
; how many times EFLAGS must be shifted right to shift the selected flag 
; into the Carry flag.

	ShowCC "Equivalency(CF), 0=high or equal", 1
	ShowCC "Parity(PF)    0=odd or no parity", 3
	ShowCC "Equal to Zero(ZF),    0=not zero", 7
	ShowCC "Is Signed(SF)          0=no sign", 8
	ShowCC "Overflow(OF)       0=no overflow", 12
	
        call   	Crlf
	popfq
	pop 	rax		; restore reg
	ret             	; Return to caller
;--------------- End of DumpCC --------------------------




;-----------------------------------------------------------------------------
DumpEflags:
;
; Displays all the eflags.
;
; Note: All register contents are preserved.
;
; Receives: nothing.
;
; Returns: nothing.
;; 
;-----------------------------------------------------------------------------
segment .data
segment .text
	push 	rax		; save reg
	pushfq			; push extended flags
	pushfq			; push flags again, and
	pop  	qword [eflags]	; save them in a variable

; Show the flags (using the eflags variable). The integer parameter indicates
; how many times EFLAGS must be shifted right to shift the selected flag 
; into the Carry flag.
        call     Crlf
        call     Crlf
	ShowFlag "CF", 1
	ShowFlag "PF", 3
	ShowFlag "AF", 5
	ShowFlag "ZF", 7
	ShowFlag "SF", 8 
	ShowFlag "TF", 9
	ShowFlag "IF", 10
	ShowFlag "DF", 11
	ShowFlag "OF", 12
	ShowFlag "NT", 15
	ShowFlag "RF", 17
	ShowFlag "VM", 18
        call   	Crlf
	ShowFlag "AC", 19
	ShowFlag "VIF", 20
	ShowFlag "VIP", 21
	ShowFlag "ID", 22
        call   	Crlf
	call 	Crlf
	popfq
	pop 	rax		;restore reg
	ret             ; Return to caller
;--------------- End of DumpEflags ------------------------------------------



;-----------------------------------------------------------------------------
DumpRegs:
;
; Displays first eight general registers  in hex.
; Also displays the Zero, Sign, Carry, and Overflow flags.
;
; Note: All register contents are preserved.
;
; Receives: nothing.
;
; Returns: nothing.
;
; Warning: do not create any local variables or stack
; parameters, because they will alter the EBP register.
;-----------------------------------------------------------------------------
segment .data
saveIP  dq 	0
saveESP dq  	0

segment .text
	pop 	qword [saveIP]	; get current EIP
	mov 	qword [saveESP],rsp	; save ESP's value at entry
	push 	qword [saveIP]	; replace it on stack
	push 	rax		; save RAX (restore on exit)
	pushfq			; push extended flags
	pushfq			; push flags again, and
	pop  	qword [eflags]	; save them in a variable
	mShowRegister "RAX",RAX  
	mShowRegister "RBX",RBX
        call 	Crlf
	mShowRegister "RCX",RCX
	mShowRegister "RDX",RDX
	call   	Crlf
	mShowRegister "RSI",RSI
	mShowRegister "RDI",RDI
        call 	Crlf
	mShowRegister "RBP",RBP
	mov 	rax, qword [saveESP]
	mShowRegister "RSP",RAX
	call    Crlf
	mov 	rax, qword [saveIP]
	mShowRegister "RIP",RAX
	mov 	rax, qword [eflags]
	mShowRegister "RFL",RAX
        call 	Crlf
  	mShowRegister "R8 ",R8  
	mShowRegister "R9 ",R9  
	call    Crlf
	mShowRegister "R10",R10
	mShowRegister "R11",R11
        call Crlf
  	mShowRegister "R12",R12  
	mShowRegister "R13",R13  
	call    Crlf
	mShowRegister "R14",R14
        mShowRegister "R15",R15

; Show the flags (using the eflags variable). The integer parameter indicates
; how many times EFLAGS must be shifted right to shift the selected flag 
; into the Carry flag.
        call     Crlf
        call     Crlf
	ShowFlag "CF", 1
	ShowFlag "PF", 3
	ShowFlag "AF", 5
	ShowFlag "ZF", 7
	ShowFlag "SF", 8 
	ShowFlag "TF", 9
	ShowFlag "IF", 10
	ShowFlag "DF", 11
	ShowFlag "OF", 12
	ShowFlag "NT", 15
	ShowFlag "RF", 17
	ShowFlag "VM", 18
        call   	Crlf
	ShowFlag "AC", 19
	ShowFlag "VIF", 20
	ShowFlag "VIP", 21
	ShowFlag "ID", 22
drexit:
	call   	Crlf
        call   	Crlf
	popfq
	pop 	rax
	ret             ; Return to caller
;--------------- End of DumpRegs ---------------------


;--------------------------------------------------------
ParseDecimal64:
;
; Converts (parses) a string containing an ASCII unsigned decimal
; numeral, and converts it to binary. All valid digits occurring 
; before a non-numeric character are converted. 
; Leading spaces are ignored.
;
; Receives: RDX = address of string 
;           RCX = length
; 
; Returns:
;  If the integer is blank, RAX=0 and CF=1
;  If the integer contains only spaces, RAX=0 and CF=1
;  If the integer is larger than 2^32-1, RAX=0 and CF=1
;  Otherwise, RAX=converted integer, and CF=0
;--------------------------------------------------------
	enter 4, 0
	push 	rbx
	push 	rcx
	push 	rdx
	push 	rsi
	mov   rsi, rdx          ; save offset in ESI
	cmp   rcx,0            	; length greater than zero?
	jne   .L1              	; yes: continue
	mov   rax,0            	; no: set return value
	jmp   .L5              	; and exit with CF=1

; Skip over leading spaces, tabs
.L1:	
        mov   al, byte [rsi]    ; get a character from buffer
	cmp   al, ' '  		; space character found?
	je    .L1               ; yes: skip it
	cmp   al, TAB		; TAB found?
	je    .L1A		; yes: skip it
	jmp   .L2      		; no: goto next step
.L1A:
	inc   rsi    		; yes: point to next char
	loop  .L1		; continue searching until end of string
	jmp   .L5		; exit with CF=1 if all spaces

; Start to convert the number.
.L2:	
        mov  rax, 0    		; clear accumulator
	mov  rbx, 1    		; EBX is the divisor

; Repeat loop for each digit.
.L3:	
        mov  dl, byte [rsi]	; get character from buffer
	cmp  dl, '0'		; character < '0'?
	jb   .L4
	cmp  dl, '9'		; character > '9'?
	ja   .L4
	and  rdx, 0Fh		; no: convert to binary
	mov  qword [rbp - 8], rdx
	mul  rbx		; multiply
	jc   .L5		; quit if Carry (EDX > 0)
	mov  rdx, qword [rbp - 8]
	add  rax, rdx 		; add new digit to sum
	jc   .L5		; quit if Carry generated
	inc  rsi              	; point to next digit
	jmp  .L3		; get next digit
.L4:	
        clc			; succesful completion (CF=0)
	jmp  .L6
.L5:	mov  rax, 0		; clear result to zero
	stc			; signal an error (CF=1)
.L6:	
	pop 	rsi
	pop 	rdx
	pop 	rcx
	pop 	rbx
	leave
	ret
;--------------- End of ParseDecimal64 ---------------------


;--------------------------------------------------------
ParseInteger64:
;
; Converts a string containing an ASCII signed decimal numeral
; digits to signed binary integer. 
;
; All valid digits occurring before a non-numeric character
; are converted. Leading spaces are ignored, and an optional 
; leading + or - sign is permitted. If the string is blank, 
; a value of zero is returned.
;
; Receives: RDX = string address (address of a null terminated string), 
;           RCX = string length (inclusive of NULL)
;
; Returns:  If CF=0, the integer is valid,
;           RAX = binary value.
;           If CF=1, the integer is invalid
;           RAX = 0.
;
;--------------------------------------------------------
segment .data
overflow_msgL db  " <64-bit integer overflow>",0
invalid_msgL  db  " <invalid integer>",0
highneg  dq   8000000000000000h

segment .text
	enter 	16, 0		; [rbp - 4]: Lsign; [rbp - 8]:saveDigit
	push  	rbx
	push  	rcx
	push  	rdx
	push  	rsi
	mov   	qword [rbp - 8], 1  ; assume number is positive
	mov   	rsi, rdx        ; save offset in SI
	cmp   	rcx, 0          ; length greater than zero?
	jne   	.L1             ; yes: continue
	mov   	rax, 0          ; no: set return value
	jmp   	.L10            ; and exit

; Skip over leading spaces and tabs.
.L1:	
        mov   	al, byte [rsi]  ; get a character from buffer
	cmp   	al, ' '       	; space character found?
	je    	.L1A	        ; yes: skip it
	cmp   	al, TAB		; TAB found?
	je    	.L1             ; yes: skip it
	jmp   	.L2     	; no: goto next step
.L1A:
	inc   	rsi 		; yes: point to next char
	loop  	.L1		; continue searching until end of string
	mov   	rax, 0          ; all spaces?
	jmp   	.L10		; return 0 as a valid value

; Check for a leading sign.
.L2:	
        cmp   	al, '-'         ; minus sign found?
	jne   	.L3             ; no: look for plus sign
	mov   	qword [rbp - 8], -1 ; yes: sign is negative
	dec   	rcx             ; subtract from counter
	inc   	rsi             ; point to next char
	jmp   	.L3A
.L3:	
        cmp   	al, '+'         ; plus sign found?
	jne   	.L3A    	; no skip
	inc   	rsi             ; yes: move past the sign
	dec   	rcx             ; subtract from digit counter

; Test the first digit, and exit if nonnumeric.
.L3A:   
        mov  	al, byte [rsi]  ; get first character
	call 	IsDigit         ; is it a digit?
	jnz  	.L7A            ; no: show error message

; Start to convert the number.
.L4:	
        mov   	rax, 0          ; clear accumulator
	mov   	rbx, 10         ; RBX is the multiplier of 10

; Repeat loop for each digit.
.L5:	
        mov  	dl, byte [rsi]  ; get character from buffer
	cmp  	dl, '0'         ; character < '0'?
	jb   	.L9
	cmp  	dl, '9'         ; character > '9'?
	ja   	.L9
	and  	rdx, 0Fh        ; drop leading nibble
	mov  	qword [rbp - 16], rdx
	imul 	rbx             ; RDX:RAX = RAX * RBX
	mov  	rdx, qword [rbp - 16]
	jo   	.L6             ; quit if overflow
	add  	rax, rdx        ; add new digit to RAX
	jo   	.L6             ; quit if overflow
	inc  	rsi             ; point to next digit
	jmp  	.L5             ; get next digit

; Overflow has occured, unless RAX has sign bit set and other zero.
; and the sign is negative:
.L6:	
        cmp  	rax, highneg    ; compare against highest neg
        jne  	.L7
	cmp  	qword [rbp - 8], -1  ; check high-order bit for neg
        jne  	.L7             ; overflow occurred
        jmp  	.L9             ; the integer is valid

; Choose "integer overflow" messsage.
.L7:    
        mov  	rdx, overflow_msgL
        jmp  	.L8

; Choose "invalid integer" message.
.L7A:
        mov  	rdx, invalid_msgL

; Display the error message pointed to by RDX, and set the Overflow flag.
.L8:	
	call 	WriteString
        call 	Crlf
        mov  	al, 127
        add  	al, 1           ; set Overflow flag
        mov  	rax, 0          ; set return value to zero
        jmp  	.L10            ; and exit

; IMUL leaves the Sign flag in an undeterminate state, so the OR instruction
; determines the sign of the integer in RAX.
.L9:	imul 	qword [rbp - 8] ; RAX = RAX * sign
	or   	rax, rax        ; determine the number's Sign

.L10:
	pop 	rsi             ; restore regs
	pop 	rdx
	pop 	rcx
	pop 	rbx
	leave
	ret
;--------------- End of ParseInteger64 ---------------------


;---------------------------------------------------------
StrLength:
;
; Obtains the length of a null-terminated string.
;
; Receives: RDX = address of string
;
; Returns:  RAX = string length (excluding the NULL byte)
;---------------------------------------------------------
	push 	rdi
	push	rcx
	xor	rcx, rcx	; clear to zero
	mov  	rdi, rdx	; set dest to forward on stack 
	not	rcx		; complement for highest int
	xor	rax, rax	; clear to zero
	cld			; forward
	repne 	scasb		; scan for NULL
	not	rcx		; complement back
        dec     rcx             ; minus 1
        mov     rax, rcx        ; result is length
	pop	rcx		;
	pop	rdi		;
	ret                   	; return to sender
;--------------- End of StrLength ------------------------


;---------------------------------------------------------
Str_length:
;
; Obtains the length of a null-terminated string.
;
; Receives: RSP = address of string
;
; Returns:  RAX = string length (including the NULL)
;---------------------------------------------------------
	push 	rdi
	push 	rbp
	mov  	rbp, rsp	; copy register contents
	mov  	rdi, [rbp + 24] ; set dest to forward on stack 
	mov  	rax, 0          ; init :character count
.L1:
	cmp  	byte [rdi], 0   ; end of string?
	je   	.L2	    	; yes: quit
	inc  	rdi	        ; no: point to next
	inc  	rax            	; add 1 to count
	jmp  	.L1
.L2:	
	pop  	rbp
	pop  	rdi
	ret                   	; return to sender
;--------------- End of Str_length -----------------------


;----------------------------------------------------------
Str_compare:
;
; Compare two strings.
;
; Receive: RBP = address of the base stack of first and the second strings.
;
; Returns: nothing, but the Zero and Carry flags are affected
;          exactly as they would be by the CMP instruction.
;-----------------------------------------------------
    	enter 0, 0  
	SaveRegs
    	mov 	rsi, qword [rbp + 16]
    	mov 	rdi, qword [rbp + 24]
.L1: 	
	mov  	al, byte [rsi]
    	mov  	dl, byte [rdi]
   	cmp  	al, 0    		; end of string1?
    	jne  	.L2      		; no
    	cmp  	dl,0    		; yes: end of string2?
    	jne  	.L2      		; no
    	jmp  	.L3      		; yes, exit with ZF = 1
.L2: 	
	inc  	rsi      		; point to next
    	inc  	rdi
    	cmp  	al, dl   		; chars equal?
    	je   	.L1      		; yes: continue loop
	          	     		; no: exit with flags set
.L3:
	RestoreRegs
    	leave
    	ret
;--------------- End of Str_compare -----------------------


;---------------------------------------------------------
Str_copy:
;
; Copy a string from source to target.
;
; Receives: RBP = address of the base of first and second strings
;
; Requires: the target string must contain enough
;           space to hold a copy of the source string.
;----------------------------------------------------------
	enter 0, 0 
	SaveRegs
	INVOKE Str_length, {[rbp + 16]}	; EAX = length source
	mov 	rcx, rax		; REP count
	inc 	rcx         		; add 1 for null byte
	mov 	rsi, qword [rbp + 16]
	mov 	rdi, qword [rbp + 24]
	cld               		; direction = up
	rep 	movsb   		; copy the string
    	RestoreRegs
	leave
	ret
;--------------- End of Str_copy -----------------------


;-----------------------------------------------------------
Str_trim:
;
; Remove all occurences of a given character from
; the end of a string.
;
; Receives: RBP = address of the current stack.
;
; Returns: nothing
;-----------------------------------------------------------
	enter 0, 0
	SaveRegs 
	mov  rdi, qword [rbp + 16]
	INVOKE 	Str_length, rdi		; returns length in RAX
	cmp  	rax,0			; zero-length string?
	je   	.L2			; yes: exit
	mov  	rcx, rax		; no: counter = string length
	dec  	rax                     ; minus 1
	add  	rdi, rax		; EDI points to last char
	mov  	al, byte [rbp + 24] 	; char to trim
	std				; direction = reverse
	repe 	scasb			; skip past trim character
	jne  	.L1			; removed first character?
	dec  	rdi			; adjust EDI: ZF=1 && ECX=0
.L1:	
	mov  	byte [rdi + 4], 0	; insert null byte
.L2:	
     	RestoreRegs
	leave
	ret
;--------------- End of Str_trim -----------------------


;---------------------------------------------------
Str_ucase:
;
; Convert a null-terminated string to upper case.
;
; Receives: RBP = address of the base stack of the string.
;
; Returns: nothing
;---------------------------------------------------
	enter 0, 0
	push 	rax
	push 	rsi
	mov 	rsi, qword [rbp + 16]
.L1:
	mov 	al, byte [rsi]		; get char
	cmp 	al, 0			; end of string?
	je  	.L3			; yes: quit
	cmp 	al, 'a'			; below "a"?
	jb  	.L2
	cmp 	al, 'z'			; above "z"?
	ja  	.L2
	and 	byte [rsi], 11011111b	; convert the char
.L2:
	inc 	rsi			; next char
	jmp 	.L1
.L3: 
	pop 	rsi
	pop 	rax
	leave
	ret
;--------------- End of Str_ucase -----------------------


;------------------------------------------------------------
BufferFlush:
;
; Clear the reading buffer and reset it to the initial state.
;
; Receives: nothing
;
; Returns:  nothing
;----------------------------------------------------------
	mov 	dword [bytesRead], 0
	mov 	dword [bufferCnt], 1
	ret
;------------------ End of BufferFlush --------------------


;------------------------------------------------------------
ReadKeys:
;
; Read keys from buffer, if there is no keys in it, read from STDIN and
; store in buffer.
;
; Receives: RCX = Number of key to return
;	    RDX = address of input buffer
;
; Returns:  nothing
;----------------------------------------------------------
	enter 4, 0
       	SaveRegs
	CheckInit
	cmp dword [bytesRead], 0 ; check if no keys in the buffer
	je .NoKey
.Begin:
	cmp rcx, qword [bytesRead]	; else, return the keys from buffer
	jbe .L1
	mov rcx, qword [bytesRead]
.L1:
	mov qword [rbp - 8], rcx
	sub qword [bytesRead], rcx
	mov rdi, rdx        	; copy the content of buffer to destination
	mov rsi, buffer
	add rsi, qword [bufferCnt]
	dec rsi
	cld
	rep movsb
	mov rbx, buffer
	add rbx, bufferMax
	cmp qword [bytesRead], 0  ; if number of left bytes is greater than 0
	jbe .L2
	cmp rsi, rbx	    	; if out of bound
	jae .L2
	mov al, byte [rsi]  	; check if next char is NL
	cmp al, NL
	jne .L2
	dec qword [bytesRead]   ; mov forword
	inc rsi
.L2:
	sub rsi, buffer
	inc rsi
	mov qword [bufferCnt], rsi
	jmp .L3
.NoKey:
	call BufferFlush; if no Key, read from the keyboard
	push rax
	push rdx
        mov rax, 0
        mov rdi, 0
	mov rsi, buffer
	mov rdx, bufferMax
	syscall
	pop rdx
	pop rax
	mov qword [bytesRead], rax
	cmp rax, 1
	ja .next
	mov al, byte [buffer]
	cmp al, NL
	je .NoKey
.next:
	jmp .Begin
.L3:
       	RestoreRegs
	mov rax, qword [rbp - 8]
	leave
	ret
;--------------------- End of ReadKeys ----------------------


;------------------------------------------------------------
ReadChar:
;
; Reads one character from the keyboard.
; Waits for the character if none is currently in the input buffer.
; 
; Receives: nothing
;.
; Returns:  AL = ASCII code
;----------------------------------------------------------
	enter 4, 0
	push  	rbx
	push  	rdx
.L1:	
	mov  	rcx, 1
	mov  	rdx, rbp
	sub  	rdx, 4
	call 	ReadKeys
	mov  	al, byte [rbp - 8]
	pop  	rdx
	pop  	rbx
	leave
	ret
;--------------- End of ReadChar -------------------------


;--------------------------------------------------------
ReadDec:
;
; Reads a 64-bit unsigned decimal integer from the keyboard,
; stopping when the Enter key is pressed.All valid digits occurring 
; before a non-numeric character are converted to the integer value. 
; Leading spaces are ignored.
;
; Receives: nothing
;
; Returns:
;  If the integer is blank, RAX=0 and CF=1
;  If the integer contains only spaces, RAX=0 and CF=1
;  If the integer is larger than 2^36-1, RAX=0 and CF=1
;  Otherwise, RAX=converted integer, and CF=0
;--------------------------------------------------------

	mov   	rdx, digitBuffer
	mov	rcx, MAX_DIGITS
	call  	ReadString
	mov	rcx, rax	; save length
	call	ParseDecimal64	; returns RAX
	ret
;--------------- End of ReadDec ------------------------


;--------------------------------------------------------
ReadHex:
;
; Reads a 64-bit hexadecimal integer from the keyboard,
; stopping when the Enter key is pressed.
;
; Receives: nothing
;
; Returns: RAX = binary integer value
;  If the integer is blank, RAX=0 and CF=1
;  If the integer contains only spaces, RAX=0 and CF=1
;  Otherwise, RAX=converted integer, and CF=0
;
; Remarks: No error checking performed for bad digits
; or excess digits.
;--------------------------------------------------------
segment .data
xbtable db  0,1,2,3,4,5,6,7,8,9
	 times 15 db 0FFh
	db  10,11,12,13,14,15
numVal  dd  0
charVal db  0

segment .text
	push rbx
	push rcx
	push rdx
	push rsi
	mov   rdx, digitBuffer
	mov   rsi, rdx		; save in ESI also
	mov   rcx, MAX_DIGITS
	call  ReadString	; input the string
	mov   rcx,rax          	; save length in ECX
	cmp   rcx, 0           	; greater than zero?
	jne   .B1              	; yes: continue
	jmp   .B8              	; no: exit with CF=1

; Skip over leading spaces and tabs.
.B1:	mov   al, byte [rsi] 	; get a character from buffer
	cmp   al, ' '        	; space character found?
	je    .B1A		; yes: skip it
	cmp   al, TAB		; TAB found?
	je    .B1A		; yes: skip it
	jmp   .B4              	; no: goto next step
.B1A:
	inc    rsi     		; yes: point to next char
	loop  .B1		; all spaces?
	jmp   .B8		; yes: exit with CF=1

	; Start to convert the number.
.B4:	mov  qword [numVal], 0	; clear accumulator
	mov  rbx, xbtable	; translate table

	; Repeat loop for each digit.
.B5:	mov  al, byte [rsi]	; get character from buffer
	cmp  al, 'F'		; lowercase letter?
	jbe  .B6		; no
	and  al, 11011111b	; yes: convert to uppercase

.B6:	sub  al, 30h		; adjust for table
	xlat  			; translate to binary
	mov  byte [charVal], al
	mov  rax, 16		; numVal *= 16
	mul  qword [numVal]
	mov  qword [numVal], rax
	movzx rax, byte [charVal]	; numVal += charVal
	add  qword [numVal], rax
	inc  rsi		; point to next digit
	loop .B5		; repeat, decrement counter
.B7:	
	mov  rax, qword [numVal]	; return valid value
	clc			; CF=0
	jmp  .B9
.B8:	
	mov  rax, 0		; error: return 0
	stc			; CF=1
.B9:
	pop rsi
	pop rdx
	pop rcx
	pop rbx
	ret
;--------------- End of ReadHex ------------------------


;--------------------------------------------------------
ReadInt:
;
; Reads a 64-bit signed decimal integer from standard
; input, stopping when the Enter key is pressed.
; All valid digits occurring before a non-numeric character
; are converted to the integer value. Leading spaces are
; ignored, and an optional leading + or - sign is permitted.
; All spaces return a valid integer, value zero.
;
; Receives: nothing
;
; Returns:  If CF=0, the integer is valid, and RAX = binary value.
;           If CF=1, the integer is invalid and RAX = 0.
;--------------------------------------------------------
	push  	rdx
	push  	rcx
; Input a signed decimal string.
	mov   	rdx, digitBuffer
	mov   	rcx, MAX_DIGITS
	call  	ReadString
	mov   	rcx, rax	; save length in RCX

; Convert to binary (RDX -> string, RCX = length)	
	call 	ParseInteger64	; returns RAX, CF
	pop  	rcx
	pop  	rdx
	ret
;--------------- End of ReadInt ------------------------


;--------------------------------------------------------
ReadStr:
;
; Reads a string from the keyboard and places the characters
; in a buffer.
;
; Receives: RDX = address of the input buffer
;           RCX = maximum characters to input (including NULL byte)
;
; Returns:  RAX = size of the input string.
;
; Comments: Stops when Enter key (0Dh,0Ah) is pressed. If the user
; types more characters than (RCX-1), the excess characters
; are ignored.
;--------------------------------------------------------
	enter 16, 0    		; bufSize: rbp - 8
		      		; bytesRead: rbp - 16
       	SaveRegs
	mov 	rdi,rdx		; set to buffer offset
	mov 	qword [rbp - 8], rcx	; save buffer size
	call 	ReadKeys
	mov 	qword [rbp - 16], rax
	cmp 	rax, 0
	jz  	.L5 		; skip move if zero chars input
	cld			; search forward
	mov 	rcx, qword [rbp - 8]	; repetition count for SCASB
	dec 	rcx
       	xor 	rax, rax   	; clear to zero 
	mov 	al, NL		; scan for 0Ah (Line Feed) terminal character
	repne 	scasb
	jne 	.L1		; if not found, jump to L1
; if we reach this line, length of input string <= (bufsize - 2)

	dec 	qword [rbp - 16]    ; second adjustment to bytesRead
	dec 	rdi		; 0Ah found: back up two positions
	cmp 	rdi, rdx 	; don't back up to before the user's buffer
	jae 	.L2
	mov 	rdi,rdx 	; 0Ah must be the only byte in the buffer
	jmp 	.L2		; and jump to L2
.L1:	
	mov 	rdi,rdx		; point to last byte in buffer
	add 	rdi,qword [rbp - 8]
	dec 	rdi
	mov 	byte [rdi],0    ; insert null byte

; Clear excess characters from the buffer, 1 byte at a time
.L6:	
	call 	BufferFlush
	jmp 	.L5

.L2:	mov 	byte [rdi],0	; insert null byte

.L5:	
       	RestoreRegs
	mov 	rax, qword [rbp - 16]
	leave
	ret
;--------------- End of ReadStr -------------------------


;--------------------------------------------------------
ReadString:
;
; Reads a string from the keyboard and places the characters
; in a buffer.
;
; Receives: RDX = address of the input buffer to place the data.
;           RCX = maximum characters to input (including terminal null)
;
; Returns:  RAX = size of the input string.
;
; Notes: Stops when Enter key (0Dh,0Ah) is pressed. If the user
; types more characters than (RCX-1), the excess characters
; are ignored.
;--------------------------------------------------------

       	push    rdx             ; save reg
       	push    rsi
       	push    rdi 
        push   	rcx
       	mov     rsi, rdx        ; offset to input buffer
       	mov     rdx, rcx        ; max number of chars accepted
       	mov     rax, 0          ; sys_read
       	mov     rdi, 0          ; stdin
       	syscall                 ;read text input from keyboard
	cmp 	rax, 0		; test for no input
	jz  	.L3 		; skip move if zero chars input
        mov 	rdi, rsi        ; point to begin
	cld			; reset to search forward
	mov 	rcx, rax       	; repetition count for SCASB
       	xor 	rax, rax   	; clear to zero 
	mov 	al, NL		; scan for 0Ah (Line Feed)
	repne 	scasb
	jne 	.L1		; if not found, jump to L1

; if we reach this line, length of input string <= (bufsize - 2)
        mov 	rax, rdi
        sub 	rax, rsi        ; string length including 0Ah
	dec 	rdi		; 0Ah found: back up two positions
	cmp 	rdi, rsi 	; don't back up to before the user's buffer
	jae 	.L2
	mov 	rdi, rsi 	; 0Ah must be the only byte in the buffer
	jmp 	.L2		; and jump to L2
.L1:	
	mov 	rdi, rsi	; point to last byte in buffer
	dec 	rdi
	mov 	byte [rdi], 0  	; insert null byte
	call 	BufferFlush
	jmp 	.L3
.L2:	
	mov 	byte [rdi],0	; insert null byte
.L3:	
	pop   	rcx
       	pop   	rdi
       	pop   	rsi
       	pop   	rdx              ; recover regs
       	ret                     ; return to caller
;--------------- End of ReadString --------------------


;--------------------------------------------------------
FileOpen:
;
; Opens target file.
;
; Receives: RDI = address of filename
;
;	    RSI = 0 read-only
;               = 1 write if not exist already
;               = 0102o Write regardless
;                
;           RDX = access permissions on write	
;          
; Returns:  RAX = file descriptor.
;  	        = -(n) on Error
;	
; Notes:         
;--------------------------------------------------------
segment	.data

segment .text
       	push	rax
	push	rsi
	push	rdx
	mov	rax, 2		; sys_open
;	mov	rdx, 0		; permission mode
	syscall			; SVC to open
	pop	rdx
	pop	rsi
	pop	rdx
	ret               	; return to caller

;------------------ End of File Open --------------------


;--------------------------------------------------------
FileClose:
;
; Opens target file.
;
; Receives: RDI = file descriptor
;
;	             
; Returns:  RAX = 0 on Success.
;  	        = -(n) on Error
;	
; Notes:         
;--------------------------------------------------------
segment	.data

segment .text
       	push	rdi
	mov	rax, 3		; sys_close
	mov	rdx, 0		; mode
	syscall			; SVC to close file
	pop	rdi
	ret               	; return to caller

;--------------- End of Open File --------------------


;--------------------------------------------------------
FileRead:
;
; Reads a record from a file and places the characters in a buffer.
;
; Receives: RDX = address of the caller read buffer
;           RDI = file descriptor
;          
; Returns:  RAX = size of the input string up through line feed char.
;  	        =  0   on EOF
;		= -(n) on Error
;	
; Notes: Attempted internal read size is 256 bytes.
;	 Strips Line-Feed character.        
;--------------------------------------------------------
segment	.data
recpi		dq	0	; record buffer position indicator
rdbfpi		dq	0	; read buffer position indicator
readbuff	times 256 db 00h
readbfln	equ 	$-readbuff
record		dq	0	; record address save area	 
readlen		dq	0	; number of bytes from read operation
slen 	  	dq      0	; displ to scan end within readbuff
lfpos   	dq      0	; displ to 0A in readbuff
fd		dq	0	; file descriptor
remainder	dq	0	; remainder of bytes to process
bytecount	dq	0	; count of read bytes to LF
mynull 		db	00h	; null byte

segment .text
       	SaveRegs
	mov	[record], rdx	; save record address
        mov     [fd], rdi       ; save file descriptor
.NxtRec:
   	mov     rcx, [remainder]	; any residual from last read?
;mShowRegister "remainder RCX",rcx
	cmp     rcx, 0		;
	jng	.Read   	; no, need a new read
	jmp 	.ProcRes	; goto process the remainder
.Read: 
	xor	rax, rax	;
	mov	[rdbfpi], rax	; zero  
	mov	r8, readbuff	;
	mov	r9, readbfln	;
	call	ClearBuffer	; clear to nulls
        mov	rdi, [fd]       ; recover file descriptor	
       	mov     rsi, readbuff 	; offset to input buffer
       	mov     rdx, 256  	; max number of chars accepted
       	mov     rax, 0    	; sys_read
	syscall           	; read file
	mov	[remainder], rax; save number of bytes read
	;mShowRegister "read RAX",rax
	cmp 	rax, 0		; test for EOF
	jz  	.EOF 		; skip move if zero chars or EOF
        jl 	.Error		; if less than zero then error
	jmp	.ProcRes	; goto ProcRes
.ProcRes:
	mov	rdi, readbuff	; scan from addr of readbuff
	add	rdi, [rdbfpi]	; plus displacement
	mov	rcx, [remainder]; max scan length
	xor 	rax, rax   	; clear to zero 
 	mov 	al, NL		; scan for 0Ah (Line Feed)
 	cld			; reset to search forward
 	repne 	scasb		; scan
 ;mov	rsi, rdi
 ;sub	rsi, [remainder] 
 ;add    rsi, rcx
 ;mov	rbx, 2
 ;call	DumpMem
	cmp	rcx, 0		; if not found jump 
	je   	.NotFound	; no hit, goto not found	
	jmp	.Found		; if hit  then goto found

.Found:
	mov 	rax, [remainder]; 
	sub	rax, rcx	;
	dec	rax		;
	mov	[lfpos], rax	; lfpos = rem - new lf pos - 1
	mov	[remainder], rcx; rem = number not scanned
;mShowRegister "lf displ", rax
;mShowRegister "remainder", rcx
	inc     rax		; plus one
	mov	[slen], rax	; save string length 
	mov	r8, readbuff 	; source address	
	add	r8, [rdbfpi]	; plus displacement
	mov	r9, [record]	; Record address target
	add	r9, [recpi]	; plus displacement
	mov	r10, [slen]	; for length
	call	Mvcl		; Move Characters
	mov	rax, [lfpos]	; address lf position
	mov	byte [r9 + rax], 0	; change LF to NULL,
	mov	qword [recpi], 0; now zero out for next operation
	mov	rax, [rdbfpi]	; update readbuf position indicator
	add	rax, [lfpos]	;
	inc     rax		;
	mov	[rdbfpi], rax	;
	mov	rax, [bytecount]; bytecount = bytecount + this read
	add	rax, [slen]	;
	mov	[bytecount], rax;
	RestoreRegs
	mov	rax, [bytecount]; size of input string with LF
	mov	qword [bytecount], 0	;
	jmp	.GoBack		; goto caller

.NotFound:  
 	mov 	rax, [remainder]; calculate length to end of buffer
	mov	[slen], rax	; save string length 
	mov	r8, readbuff	; source address
	add	r8, [rdbfpi]	;
	mov	r9, [record]	; Record address target
	add	r9, [recpi]	;
;mShowRegister "NF recpi", r9	
 	mov	r10, [slen]	; for length
	call	Mvcl		; Move Characters
	mov	rax, [bytecount]; bytecount = bytecount + this read
	add	rax, [slen]	;
	mov	[bytecount], rax;
	mov	rax, [recpi]	; update record position indicator
	add	rax, [slen]	;
	mov	[recpi], rax	;
	mov	rax, [rdbfpi]	; update readbuf position indicator
	add	rax, [remainder];
	mov	[rdbfpi], rax	;
	xor	rax, rax	; zero out
	mov	[lfpos], rax	; reset to zero position
	mov	[remainder], rax; reset to zero
	jmp	.NxtRec		; goto process next record
.Error:
	RestoreRegs
	jmp	.GoBack
.EOF:
	mov	rax, [recpi]	; update record position indicator
 	cmp	rax, 0		; if fpi <= readbuf length
 	jg	.Resid		; flush the residual to caller
	jmp	.EOFONLY	; just the EOF
.Resid:
	xor	rax, rax	; zero out
	mov	[lfpos], rax	; reset to zero position
	mov	[remainder], rax; reset to zero
	RestoreRegs
	mov	rax, [recpi]	; residual count
	mov	qword [recpi], 0; now zero out for next operation
	jmp	.GoBack
.EOFONLY:
	RestoreRegs		
	mov	rax, 0		; signal the EOF
	jmp	.GoBack
.GoBack:
	ret               	; return to caller
;--------------- End of FileRead --------------------


;--------------------------------------------------------
FileWrite:
;
; Writes a record to a file from the characters in a buffer.
;
; Receives: RDX = address of the caller write buffer
;           RDI = file descriptor
;           RCX = byte count
;          
; Returns:  RAX = size of the output string written.
;  	        =  0   on EOF
;		= -(n) on Error
;	
; Notes:         
;--------------------------------------------------------
segment	.data
wrecord	dq	0		; record address save area	 
wfd	dq	0		; file descriptor
wnull 	db	00h		; null byte

segment .text
       	SaveRegs
	mov	[wrecord], rdx	; save record address
        mov     [wfd], rdi      ; save file descriptor
.Write: 
	mov	rdi, [wfd]      ; recover file descriptor	
       	mov     rsi, [wrecord] 	; offset to record buffer
       	mov     rdx, rcx  	; max number of chars accepted
       	mov     rax, 1    	; sys_read
	syscall           	; read file
	;mShowRegister "read RAX",rax
	jmp	.GoBack		; done
.Error:
	jmp	.GoBack
.GoBack:	
	RestoreRegs
	ret               	; return to caller
;--------------- End of FileWrite  --------------------


;------------------------------------------------------
WriteBin:
;
; Writes a 64-bit integer to the console window in
; binary format. Converted to a shell that calls the
; WriteBinB procedure, to be compatible with the
; library documentation in Chapter 5.
;
; Receives: EAX = the integer to write
;
; Returns:  nothing
;------------------------------------------------------
	push   	rbx
	mov    	rbx, 8		; select doubleword format
	call   	WriteBinB
	pop    	rbx
	ret
;--------------- End of WriteBin --------------------


;------------------------------------------------------
WriteBinB:
;
; Writes a 64-bit integer to the console in; binary format.
;
; Receives: RAX = the integer to write
;           RBX = display size (1,2,4,8)
;
; Returns:  nothing
;------------------------------  ------------------------
        SaveRegs
    	cmp	rbx, 1   	; ensure RBX is 1, 2, or 4
    	jz    	.WB0
    	cmp   	rbx, 2
    	jz    	.WB0
        cmp   	rbx, 4
        jz    	.WB0
    	mov   	rbx, 8  	; set to 8 (default)
.WB0:
    	mov   	rcx, rbx
    	shl   	rcx, 1 		; number of 4-bit groups in low end of RAX
    	cmp   	rbx, 8    	; Type 8
    	jz    	.WB0A
    	ror   	rax, 8   	 
    	cmp   	rbx, 4    	; Type 4
    	jz    	.WB0A
    	ror   	rax, 8   	 
    	cmp   	rbx, 2    	; Type 2
    	jz    	.WB0A    	
        ror   	rax, 8  
        cmp   	rbx, 1    	; Type 1
        jz    	.WB0A
    	
.WB0A:
	call 	BufferFlush
	mov   	rsi, buffer
.WB1:
	push  	rcx		; save loop count
	mov   	rcx,4		; 4 bits in each group
.WB1A:
	shl   	rax,1		; shift left logical into Carry flag
	mov   	byte [rsi], '0'	; choose '0' as default digit
	jnc   	.WB2		; if no carry, then jump to L2
	mov   	byte [rsi], '1'	; else move '1' to DL
.WB2:
	inc   	rsi
	loop  	.WB1A		; go to next bit within group
	mov   	byte [rsi], ' ' ; insert a blank space
	inc   	rsi		; between groups
	pop   	rcx		; restore outer loop count
	loop  	.WB1		; begin next 4-bit group
	dec   	rsi    		; eliminate the trailing space
	mov   	byte [rsi], 0	; insert null byte at end
	mov   	rdx, buffer	; display the buffer
	call  	WriteString
       	RestoreRegs
	ret
;--------------- End of WriteBinB --------------------

	
;------------------------------------------------------
WriteChar:
;
; Write a character to the console window
;
; Receives: AL = character
;
; Returns:  nothing
;------------------------------------------------------
       	SaveRegs
	pushfq 			; save flags
	mov  	[buffer], al    ; place low-order byte in buffer
	mov 	rax, 1
	mov 	rdi, 1         
	mov 	rsi, buffer 	; buffer addr
	mov 	rdx, 1      	; length
	syscall			; call sys_write to the char
	mov 	[bytesWritten], rax
	popfq			; restore flags
   	RestoreRegs
	ret
;--------------- End of WriteChar --------------------

	
;-----------------------------------------------------
WriteDec: 
;
; Writes an unsigned 64-bit decimal number to console.
; 
; Receives: RAX = the number to write.
;
; Returns:  nothing
;------------------------------------------------------
segment .data
; There will be as many as 10 digits.
%assign WDBUFFER_SIZE 24

bufferL: times WDBUFFER_SIZE db 0
	db    0

segment .text
       	SaveRegs
	mov   rcx, 0            ; digit counter
	mov   edi, bufferL
	add   edi, (WDBUFFER_SIZE - 1)
	mov   rbx, 10		; decimal number base
.WI1:
	mov   rdx, 0          	; clear dividend to zero
	div   rbx            	; divide EAX by the radix
	xchg  rax, rdx        	; swap quotient, remainder
	call  AsciiDigit     	; convert AL to ASCII
	mov   byte [rdi], al    ; save the digit
	dec   rdi            	; back up address in buffer
	xchg  rax, rdx        	; swap quotient, remainder
	inc   rcx            	; increment digit count
	or    rax, rax        	; quotient = 0?
	jnz   .WI1            	; no, divide again

	; Display the digits (CX = count)
.WI3:
	inc   rdi		; add 1 to address
	mov   rdx, rdi
	call  WriteString
.WI4:
	RestoreRegs
	ret
;--------------- End of WriteDec ---------------------


;------------------------------------------------------
WriteHex:
;
; Writes an unsigned 64-bit hexadecimal number to console.
;
; Receives: RAX = the number to write.
;
; Returns:  Nothing
;------------------------------------------------------
	push  	rbx
	mov   	rbx, 8
	call  	WriteHexB
	pop   	rbx
	ret
;--------------- End of WriteHex ---------------------


;------------------------------------------------------
WriteHexB:
;
; Writes an unsigned 64-bit hexadecimal number to the console.
;
; Receives: RAX = the numeric value to write. 
;           RBX = display size (1,2,4,8)
;
; Returns:  nothing
;------------------------------------------------------
%assign DOUBLEWORD_BUFSIZE 16
   
segment .data
bufferLHB: times DOUBLEWORD_BUFSIZE db 0
         db 0

segment .text
	enter 8, 0		 ; [rbp - 8]: displaySize
       	SaveRegs
 	mov qword [rbp - 8], rbx ; save component size

; Clear unused bits from RAX to avoid a divide overflow.
; Also, verify that RBX contains either 1, 2, 4, or 8. If any
; other value is found, default to 8.
	cmp rbx, 1
	jne .when2 
	and  rax, 0FFh	      	; 1 byte
	jmp .outerEndif
.when2:
        cmp rbx, 2
	jne .when4
	and  rax, 0FFFFh	; 2 bytes
	jmp .outerEndif
.when4:
	cmp rbx, 4
	jne .when8 
	and  rax, 0FFFFFFh   	; 4 bytes
	jmp .outerEndif
.when8:
;	mov qword [rbp - 16], 8  ; default 8 bytes
	mov qword [rbp - 8], 8  ; default 8 bytes
.outerEndif:
	mov   rdi, qword [rbp - 8] ; point to the end of the buffer:
	shl   rdi, 1		; multiply by 2 (2 digits per byte)
	mov   byte [bufferLHB + rdi], 0	; store null string terminator
	dec   rdi		; back up one position
	mov   rcx, 0     	; digit counter
	mov   rbx, 16		; hexadecimal base (divisor)
.L1:
	mov   rdx, 0          	; clear upper dividend
	div   rbx            	; divide EAX by the base
	xchg  rax, rdx        	; swap quotient, remainder
	call  AsciiDigit     	; convert AL to ASCII
	mov   byte [bufferLHB + rdi], al       ; save the digit
	dec   rdi             	; back up in buffer
	xchg  rax, rdx        	; swap quotient, remainder
	inc   rcx             	; increment digit count
	or    rax, rax        	; quotient = 0?
	jnz   .L1           	; no, divide again
 ; Insert leading zeros
	mov   rax, qword [rbp - 8]; set EAX to the
	shl   rax, 1		; number of digits to print
	sub   rax, rcx		; subtract the actual digit count
	jz    .L3           	; display now if no leading zeros required
	mov   rcx, rax         	; CX = number of leading zeros to insert

.L2:
	mov   byte [bufferLHB + rdi], '0'	; insert a zero
	dec   rdi               ; back up
	loop  .L2               ; continue the loop

	; Display the digits. ECX contains the number of
	; digits to display, and EDX points to the first digit.
.L3:
	mov   rcx,qword [rbp - 8]	; output format size
	shl   rcx, 1         	; multiply by 2
	inc   rdi
	mov   rdx, bufferLHB
	add   rdx, rdi
	call  WriteString
       	RestoreRegs
	leave
	ret
;--------------- End of WriteHexB ---------------------


;-----------------------------------------------------
WriteInt:
;
; Writes a 64-bit signed binary integer to console
; in ASCII decimal.
;
; Receives: RAX = the integer value
;
; Returns:  nothing
;
; Comments: Displays a leading sign, no leading zeros.
;-----------------------------------------------------
%assign WI_Bufsize 24
%assign true 1
%assign false 0

segment .data
buffer_B  times WI_Bufsize db 0
	  db  0  		; buffer to hold digits
neg_flag  db  0

segment .text
       	SaveRegs
	mov   byte [neg_flag], false    ; assume neg_flag is false
	or    rax, rax          ; is AX positive?
	jns   .WIS1             ; yes: jump to B1
	neg   rax               ; no: make it positive
	mov   byte [neg_flag], true     ; set neg_flag to true
.WIS1:
	mov   rcx, 0          	; digit count = 0
	mov   rdi, buffer_B
	add   rdi, (WI_Bufsize-1)
	mov   rbx, 10           ; will divide by 10
.WIS2:
	mov   rdx, 0            ; set dividend to 0
	div   rbx               ; divide AX by 10
	or    dl, 30h           ; convert remainder to ASCII
	dec   rdi               ; reverse through the buffer
	mov   byte [rdi], dl   	; store ASCII digit
	inc   rcx               ; increment digit count
	or    rax, rax         	; quotient > 0?
	jnz   .WIS2             ; yes: divide again

	; Insert the sign.
	dec   rdi		; back up in the buffer
	inc   rcx               ; increment counter
	mov   byte [rdi], '+' 	; insert plus sign
	cmp   byte [neg_flag], false   	; was the number positive?
	jz    .WIS3             ; yes
	mov   byte [rdi], '-' 	; no: insert negative sign

.WIS3:	; Display the number
	mov  	rdx, rdi
	call 	WriteString
	RestoreRegs
	ret
;--------------- End of WriteInt ---------------------


;--------------------------------------------------------
WriteString:
;
; Writes a null-terminated string to standard output.
;
; Receives: RDX = address of the string.
;
; Returns:  Nothing
;--------------------------------------------------------
       SaveRegs 
       INVOKE Str_length, rdx   ; return length of string in RAX
       mov    rsi, rdx 		; message addr
       mov    rdx, rax 		; length
       mov    rax, 1   		; sys_write
       mov    rdi, 1   		; sdtout 
       syscall       		; generate svc interruption
       RestoreRegs 
       ret
;--------------- End of WriteString ---------------------


;*************************************************************
;*                    PRIVATE PROCEDURES                     *
;*************************************************************

;--------------------------------------------------------
AsciiDigit:
;
; Convert AL of the RAX register from hex to an ASCII digit.
;
; Receives: AL must contain Hex digit
;
; Returns:  Nothing 
;--------------------------------------------------------
	 push  	rbx
	 mov   	rbx, xtable     ; address xtable
	 xlat                	; translate
	 pop   	rbx
	 ret
;---------------- End of AsciiDigit ---------------------


;--------------------------------------------------------
HexByte:
;
; Convert by in AL to hex and display.
;
; Receives: AL contains hex digit.
;
; Returns:  Nothing
;--------------------------------------------------------
       	SaveRegs 
	mov   dl, al
	rol   dl, 4
	mov   al, dl
	and   al, 0Fh
	mov   rbx, xtable
	xlat
	call  BufferFlush
	mov   byte [buffer], al		; save first char
	rol   dl, 4
	mov   al, dl
	and   al, 0Fh
	xlat
	mov   byte [buffer+1], al	; save second char
	mov   byte [buffer+2], 0	; null byte
	mov   rdx,buffer		; display the buffer
	call  WriteString
	call  BufferFlush
      	RestoreRegs 
	ret
;------------------ End of HexByte ---------------------
