;64-bit "Hello World!" in Linux NASM

global  main               ; global entry point export for ld

section .text
main:
  
    	mov	rax, 1          ; sys_write
    	mov    	rdi, 1          ; stdout
    	mov    	rsi, message    ; message address
    	mov    	rdx, length     ; message string length
    	syscall
; program suspended waiting for write to terminal
 
    	mov    	rax, 60         ; sys_exit
    	xor    	rdi, rdi        ; return 0 (success)
    	syscall

section .data
message: db   0Dh,0Ah,'Hello, World!',0Dh,0Ah,0Dh,0Ah   ; message and CRLF
length:  equ  $-message        ; NASM definition pseudo-instruction
