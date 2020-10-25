;  Source name     : challenges_solved.asm
;  Executable name : numberedtextfile
;  Created date    : Oct. 24. 2020
;  Last update     : Oct. 25. 2020
;  Author          : Malak Alhazmi
;  Description     : A text file I/O demo for Linux, using NASM 2.13.02
;                    The program does the following:
;                    (1)Reads a txt file that does not have numbers prepend in front of its lines.
;                    (2)Write it out again with line numbers.
;                    (3)Allow the user to enter on the command-line the name of the new file that will contain the modified txt.
;                    (4)Small help system that instructs and guides the user when they need.
;  NOTE            : This project is the solution for the problem/challeng that was intoduced by Jeff Duntemann in his book 
;                    (Assembly Language Step by Step Programming with Linux - Third Edition) page #495.
;
;  Build using these commands in (makefile):
;        numberedtextfile: challenges_solved.o
;           gcc -m32 challenges_solved.o -o numberedtextfile
;        challenges_solved.o: challenges_solved.asm
;           nasm -f elf -g -F dwarf challenges_solved.asm
;


[SECTION .data]			; Section containing initialised data

Filename    db 'notNumberdFile.txt',0			
WriteBase   db '#%d: %s',0
WriteCode   db 'w',0
OpenCode    db 'r',0			
HelpMsg     db 'PLEASE write the name you desire for the new file you want to create! type it in the command-line as Arg(1)',10,0
ErrMsg      db 'The input file (notNumberdFile.txt) is not exist or there was a problem while reading it!',10,0


[SECTION .bss]			; Section containing uninitialized data

LENLIMIT     EQU 80	    	  ; Define length limit of a single line of [(1)help text from memory/(3)notNumberdFile.txt]
LineBuff     resb LENLIMIT	; Reserve space for [(1)text line of disk-based help/(2)text line of input file "notNumberdFile.txt"] 
BUFSIZE      EQU 30         ; Define max length of output file name arg
FileNameArg  resb BUFSIZE   ; Reserve space for output file name arg 


[SECTION .text]			; Section containing code

;; These externals are all from the glibc standard C library:	 
extern fopen
extern fclose
extern fgets	
extern fprintf
extern printf		

global main			; Required so linker can find entry point
	
main:
  push ebp	  	; Set up stack frame for debugger
	mov ebp,esp
	push ebx		  ; Program must preserve EBP, EBX, ESI, & EDI
	push esi
	push edi
;;; Everything before this is boilerplate; use it for all ordinary apps!	


;;;;;; ((( 1 )))--> test  to see if there are command line arguments at all.
	;; If there are none, we show the help info.  
	;; Don't forget that the first arg is always the program name, so there's
	;; always at least 1 command-line argument!
	mov eax,[ebp+8]		; Load argument count from stack into EAX
	cmp eax,1		      ; If count is 1, there are no args
	ja getfilename	  ; Continue if arg count is > 1 
	call help		      ; If only 1 arg, show help info...
	jmp gohome		    ; ...and exit the program

	
;;;;;; ((( 2 )))--> if there is a command line argument (text file name)
	;; then we take it out of stack and keep it in the buffer (FileNameArg). 
getfilename:
  mov ebx,[ebp+12]	    ; Put pointer to argument table into ebx
	mov edi,FileNameArg		; Destination pointer is start in the buffer (FileNameArg)
	xor eax,eax		        ; Clear eax to 0 for the character counter
	cld			              ; Clear direction flag for up-memory movsb
  mov esi,[ebx+4]  	    ; Copy pointer to file name arg into esi
    
 .copy:  
  cmp byte [esi],0	    ; Have we found the end of the arg?
	je addnul		          ; If so, go add a null to buff & we're done...
	movsb			            ; Copy char from [esi] to [edi]; inc edi & esi
	inc eax			          ; Increment total character count
	cmp eax,BUFSIZE		    ; See if we've filled the buffer to max count
	je addnul		          ; If so, go add a null to buff & we're done...
	jmp .copy

addnul:	
    mov byte [edi],0	  ; Tuck a null on the end of buff


;;;;;; ((( 3 )))--> Now, we 'read' a line from the input file (notNumberdFile.txt) 
	;; and at the same time we 'write' that line along with its line# in the output file (its name is in: FileNameArg).
readwritefile:
  ;;READ (input file)
  push OpenCode	 ; Push pointer of opinning mode:read code ('r')
	push Filename	 ; Pointer to name of input file is passed in Filename
	call fopen		 ; Attempt to open the input file for reading
	add esp,8		   ; Clean up the stack
	
	cmp eax,0		   ; fopen returns null if attempted open failed
	je err		     ; if opinning of file is failed, show err msg
	
  mov ebx,eax		 ; Save handle of opened input file in ebx
    
  ;;WRITE (output file)
  push WriteCode	 ; Push pointer opinning mode: write code ('w')
	push FileNameArg ; Push pointer of new file name
	call fopen		   ; Create/open output file
	add esp,8		     ; Clean up the stack
	
	mov esi,eax		   ; Save handle of opened output file in esi
	
	xor edi,edi      ; Clear edi to 0 for the line counter
    
 .readln:	
  push ebx		  ; Push the input file handle on the stack
	push LENLIMIT	; Limit line length of text read
	push LineBuff	; Push address of line buffer
	call fgets		; Read a line of text from the input file
	add esp,12		; Clean up the stack
	cmp eax,0		  ; A returned null indicates error or EOF
	je done		    ; If we get 0 in eax, close up & return
	
	inc edi         ; Increment line counter 
	call .writeline ; Write the line in the output file
	
	jmp .readln     ; Read the next line
	
 .writeline:
	push LineBuff 	; Pointer to the line of text
	push edi		    ; The line number
	push WriteBase	; Push address of the base string
	push esi	    	; Push the file handle of the output file
	call fprintf  	; Write the text line to the file
	add esp,16      ; Clean up the stack
	ret             ; Get back to read the next line...
	
	
done:
  ;;(close input file)
  push ebx	  	; Push the handle of the input file to be closed
	call fclose		; Closes the file whose handle is on the stack
	add esp,4	  	; Clean up the stack
	;;(close output file)
	push esi		  ; Push the handle of the output file to be closed
	call fclose		; Closes the file whose handle is on the stack
	add esp,4		  ; Clean up the stack
	
	jmp gohome    ; End the program...  
	
	
	
;;; SUBROUTINES================================================================
;------------------------------------------------------------------------------
;  (1) If user did not type any name for the new file, disk-help system will tell them what to do!
;  (2) If input file was not in the directory, we will tell the user so!
;------------------------------------------------------------------------------	

;;(1)
help:
  push HelpMsg	; Push address of help line on the stack
	call printf		; Display the line
	add esp,4	  	; Clean up the stack
  ret           ; Go home
  
;;(2)
err:
  push ErrMsg	  ; Push address of err msg on the stack
	call printf	  ; Display the err msg
	add esp,4	  	; Clean up the stack
  jmp gohome    ; End the program...

	
	
;;; ===========================END=====================================	
;;; Everything after this is boilerplate; use it for all ordinary apps!
gohome:	
  pop edi			  ; Restore saved registers
	pop esi
	pop ebx
	mov esp,ebp		; Destroy stack frame before returning
	pop ebp
	ret			      ; Return control to to the C shutdown code

	
	
