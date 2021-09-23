;--------------------------- MACROS ------------------------------------------
; Change Log:
; 02-06-21 CP Rename ifndef for Exit from CPExit to Exit, update mShowRegister
;
;
;-----------------------------------------------------------------------------
%ifndef MACRO_CPSUB64
%define MACRO_CPSUB64

%define STDIN  0
%define STDOUT 1
%define STDERR 2

%define TAB 09h
%define NL 0Ah

; define the timespec structure used in nanosleep
struc timespec
     tv_sec: resd 1
     tv_nsec: resd 1
endstruc


; Synonym for NASM invoke
%ifnmacro INVOKE
%macro INVOKE 1-*.nolist
     %rep %0 - 1
     %rotate -1
     push qword %1
     %endrep
     %rotate -1
     call %1
     add rsp, ( %0 - 1 ) * 8
%endmacro
%endif


%ifnmacro mWrite
;------------------------------------------------------
%macro mWrite 1.nolist
;
; Writes a string literal to standard output.
; Receives: a string enclosed in single or double 
;   quotes (null terminator not required).
;------------------------------------------------------
segment .data
	%%string: db %1, 0
segment .text
	push	rdx
	mov	rdx,%%string
 	call	WriteString
 	pop	rdx
%endmacro
%endif


%ifnmacro mWriteSpace
;------------------------------------------------------
%macro mWriteSpace 0-1.nolist 1
;
; Writes one or more spaces to standard output.
; Receives: an integer specifying the number of spaces.
;   If count is blank, a single space is written.
;------------------------------------------------------
segment .data
%%spaces: times %1 db ' '
	db 0
segment .text
	push	rdx
	mov	rdx, %%spaces
	call	WriteString
	pop	rdx
%endmacro
%endif


%ifnmacro mShowRegister
;---------------------------------------------------
%macro mShowRegister 2.nolist
;
; Displays a 64-bit register name and its contents.
; Receives: the register string name, the register.
; Returns:  nothing
;---------------------------------------------------
segment .data
%%tempStr: db "  ", %1,": ",0

segment .text
	push	rax		; save reg	
	push	rdx 		; save reg
	mov	rdx, %%tempStr	; display the register name
	call	WriteString
	pop	rdx		; restore reg
	mov	rax, %2		; display the reg contents in hex
	call	WriteHex
	pop	rax             ; restore reg
%endmacro
%endif


%ifnmacro ShowFlag
;---------------------------------------------------------------------
%macro ShowFlag 2.nolist
;
; Helper macro.
; Display a single CPU flag value
; Directly accesses the eflags variable in Along32.asm
; (This macro cannot be placed in Macros.inc)
;---------------------------------------------------------------------
segment .data
%%flagStr: db "  ",%1, "="
%%flagVal: db 0,0

segment .text
	push rax
	push rdx
	mov  rax, qword [eflags]	; retrieve the flags
	mov  byte [%%flagVal],'1'
	shr  rax, %2			; shift into carry flag
	jc   %%L1
	mov  byte [%%flagVal],'0'
%%L1:
	mov  rdx, %%flagStr	; display flag name and value
	call WriteString
	pop  rdx
	pop  rax
%endmacro
%endif


%ifnmacro ShowCC
;---------------------------------------------------------------------
%macro ShowCC 2.nolist
;
; Helper macro.
; Display a single Condition Code Eflag name and value
; Directly accesses the eflags variable.
; 
;---------------------------------------------------------------------
segment .data
%%flagStr: db "  ",%1," : "    	; flag name plus = sign
%%flagVal: db 0,0         	; flag value if 0 or 1, plus NULL

segment .text
	push rax  		; save reg
	push rdx		; save reg
	mov  rax, qword [eflags]	; retrieve the flags
	mov  byte [%%flagVal],'1'	; ON
	shr  rax, %2		; shift into carry flag
	jc   %%L1
	mov  byte [%%flagVal],'0'	; OFF
%%L1:
	mov  rdx, %%flagStr	; display flag name and value
	call WriteString
	call Crlf		; line feed
	pop  rdx		; restore reg
	pop  rax		; restore reg
%endmacro
%endif



%ifnmacro CheckInit
;-------------------------------------------------------------
%macro CheckInit 0.nolist
;
; Helper macro
; Check to see if the console handles have been initialized
; If not, initialize them now.
;-------------------------------------------------------------
	cmp byte [InitFlag],0
	jne %%exit
	mov byte [InitFlag],1
	call BufferFlush
%%exit:
%endmacro
%endif


%ifnmacro SaveRegs
;-------------------------------------------------------------
%macro SaveRegs 0.nolist
;
; Convenience macro
; Save Registers
; PUSH the 16 general purpose regs to the stack.
;-------------------------------------------------------------
       push rax
       push rbx 
       push rcx
       push rdx
       push rsi
       push rdi
       push rbp
       push rsp
       push r8 	
       push r9  
       push r10
       push r11
       push r12
       push r13
       push r14
       push r15
%%exit:
%endmacro
%endif

%ifnmacro RestoreRegs
;-------------------------------------------------------------
%macro RestoreRegs 0.nolist
;
; Convenience macro
; Restore Registers
; POP the 16 general purpose regs from the stack.
;-------------------------------------------------------------
	pop r15
	pop r14
	pop r13
     	pop r12
	pop r11 
	pop r10
     	pop r9 
     	pop r8 
	pop rsp
      	pop rbp 
      	pop rdi
      	pop rsi
      	pop rdx
      	pop rcx 
      	pop rbx
      	pop rax
%%exit:
%endmacro
%endif

; Termination Macro
;-------------------------------------------------------------
;
; Convenience macro
; Exit to operating system under Linux.
;-------------------------------------------------------------
%ifnmacro Exit
%macro Exit 0.nolist  
     mov rax, 60
     xor rdi, rdi
     syscall
%%exit:
%endmacro
%endif

; Termination Macro
%ifnmacro CPexit
;-------------------------------------------------------------
;
; Convenience macro
; Exit to operating system under Linux.
;-------------------------------------------------------------
%macro CPexit 0-1.nolist  
     mov rax, 60
     xor rdi, rdi
     syscall
%%exit:
%endmacro
%endif

%endif  ;End of Macro Definitions
