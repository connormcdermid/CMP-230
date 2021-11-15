; ----------------------------------------------------------------------------
; stackdemo
;
; Author: Geoffrey J. Cullen
;
; Function:
; Demonstrate use and content of UNIX program stack between subroutine calls.
; 
; ----------------------------------------------------------------------------
%include "CPsub64.inc"
%include "Macros_CPsub64.inc"

         section .data
eopmsg  db     	"End-of-Program",0h
entermsg db    	"Enter the Subroutine........",0h
exitmsg db    	"Exit  the Subroutine........",0h
parm1msg db     "The Parameter (arg1) to be passed is: ",0
parm1   dq	128d
parm2msg db     "The Parameter (arg2) to be passed is: ",0
parm2   dq	512d
parm3msg db     "The Parameter (arg3) to be passed is: ",0
parm3   dq	1024d
resultmsg db   	"Returned result to Caller: ",0
result  dq	0h
arg1msg db     	"The first Argument received by Subroutine is:  ",0
arg1    dq	0h
arg2msg db     	"The second Argument received by Subroutine is: ",0
arg2    dq	0h
arg3msg db     	"The third Argument received by Subroutine is:  ",0
arg3    dq	0h
sum	dq	0h
 
        global  main
        section .text
main:
	call	Crlf
        mov     rdx, parm1msg       	; write working on N message
        call    WriteString        	; 
 	mov	rax, [parm1]        	; parameter 1
	call    WriteInt           	;
	call	Crlf			; 
        mov     rdx, parm2msg       	; write working on N message
        call    WriteString        	; 
 	mov	rax, [parm2]        	; parameter 2
	call    WriteInt           	;
	call	Crlf			; 
        mov     rdx, parm3msg       	; write working on N message
        call    WriteString        	; 
 	mov	rax, [parm3]        	; parameter 3
	call    WriteInt           	;
	call	Crlf
	call	Crlf		
	mov	r8, 1			; load with value	
	mov	r9, 2			; load with value	
	mov	r10, 3			; load with value

; Register contents to be preserved.
	call	Crlf
	mShowRegister "R8", r8
	mShowRegister "R9", r9
	mShowRegister "R10", r10
	call	Crlf
	call	Crlf

	mov	rax, [parm1]		;	
	mov	rbx, [parm2]		;	
	mov	rcx, [parm3]		;	
; Note order of pushing on to stack.
	push	rcx			; pass third parm to subroutine
	push	rbx			; pass second parm to subroutine
	push	rax			; pass first parm to subroutine
	call	DumpRegs
	call    mySubroutine1          	; call procedure
	call	DumpRegs
	add	rsp, 3*8		; rid stack of 3 stack entries (3*8)
					; by incrementing the Stack Pointer
					; register by three 8-byte positions

; Show that caller register contents were in fact preserved
	call	Crlf
	mShowRegister "R8", r8
	mShowRegister "R9", r9
	mShowRegister "R10", r10
	call	Crlf
	call	Crlf
        mov     [result], rax      	; save result
	mov	rdx, resultmsg     	; get address of output
        call    WriteString        	; call procedure
        mov     rax, [result]        	; get address of output
        call    WriteInt           	; call procedure
        call    Crlf               	;
	jmp	myExit			; goto exit

myExit:
        mov     rdx, eopmsg        	; address message
        call    WriteString        	; write end of program msg
	call 	Crlf
        Exit    



;----------------------------------------------------------------------
; Subroutine1
;
; Function: Demonstrate use of Stack to access passed arguments,
;	and protect the caller's register contents by saving as local
;	variables on the program stack. 
;
; Receives: 3 arguments
; 
; Returns: RAX, the sum of the arguments as a result.
;----------------------------------------------------------------------
mySubroutine1:
; entry linkage	
	push	rbp			; save callers base pointer (RBP)
	mov	rbp, rsp		; set new base pointer value
 	sub	rsp, 1*8		; Stack Pointer set local var1 slot

	mov	rdx, entermsg		; Display ENTER SUBROUTINE msg
	call	WriteString
	call	Crlf

; preserve the caller's register contents
	push    r8			; save callers reg in local var
	push    r9			; save callers reg in local var
	push    r10			; save callers reg in local var

; display received arguments
 	mov     rax, [rbp + 2*8]   	; load with first parameter (arg1)
        mov     [arg1], rax      	; store received arg1
 	add	[sum], rax		; add 
 	mov	rdx, arg1msg     	; get address of output
        call    WriteString        	; call procedure
        mov     rax, [arg1]        	; get address of output
        call    WriteInt           	; call procedure
        call    Crlf

 	mov     rax, [rbp + 3*8]    	; load with second parameter (arg2)
        mov     [arg2], rax      	; store received arg2
 	add	[sum], rax		; add 
	mov	rdx, arg2msg     	; get address of output
        call    WriteString        	; call procedure
        mov     rax, [arg2]        	; get address of output
        call    WriteInt           	; call procedure
	call    Crlf               	;

 	mov     rax, [rbp + 4*8] 	; load with third parameter (arg3)
        mov     [arg3], rax      	; store received arg3
 	add	[sum], rax		; add 
	mov	rdx, arg3msg     	; get address of output
        call    WriteString        	; call procedure
        mov     rax, [arg3]        	; get address of output
        call    WriteInt           	; call procedure
	call    Crlf               	;
	call	Crlf

; prepare return value
	mov	rax, [sum]		; load reg with sum

; introduce change to register values used by caller
	xor	r8, r8			; set to zero	
	xor	r9, r9			; set to zero	
	xor	r10, r10		; set to zero	
	call	DumpRegs

; recover callers register contents used by subroutine, note reverse order
        pop     r10                     ; restore callers reg contents
        pop     r9                      ; restore callers reg contents
        pop     r8                      ; restore callers reg contents
	
	mov	rdx, exitmsg		
	call	WriteString		; Display EXIT SUBROUTINE msg
	call	Crlf

; return linkage
	mov	rsp, rbp		; restore callers stack pointer (RSP)
	pop	rbp			; restore callers base pointer (RBP)
        ret                             ; return, rax contains result
