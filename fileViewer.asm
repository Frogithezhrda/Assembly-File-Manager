
section .data ;; unchangeable data(already init)
	menu db "Menu:", 0x0A, "1. List Directory", 0x0A, "2. Print File", 0x0A, "3. Navigate To Files", 0x0A, "4. Quit", 0x0A
	len equ $ - menu
	listDir db "Listing Directory:", 0x0A
	lenList equ $ - listDir
	endOption db "Bye Bye!", 0x0A
	lenEnd equ $ - endOption
	dirError db "Error Can't Read Directory!", 0x0A
	lenDirError equ $ - dirError
	dirExplanation db "Don't Forget to put the full path", 0x0A
	lenDirExplanation equ $ - dirExplanation

	newLine db 0x0A
	blueColor db 0x1B, "[34m"
	blueLen equ $ - blueColor
	resetColor db 0x1B, "[0m"
	resetLen equ $ - resetColor

section .bss ; Changeable(not init)
    inputBuffer: resb 1
    fd: resd 1
	buffer: resb 1024
	dirPath: resb 256
	fileBuffer: resb 4096
	fileName: resb 256

; code section
section .text
    global _start 

_start:
    mov byte [dirPath], '.'
    mov byte [dirPath + 1], 0
	call Main
	;endingg the program using exis=t status
	mov eax, 1 ; exit syscall
	mov ebx, 0 ;success
	int 0x80
	

	
; main function
Main: 
	push ebp
	mov ebp, esp
	menuLoop:
		;printing the menu
		push len
		push menu
		call PrintString
		;getting the value from the user
		call PickOption
		push eax
		call SwitchOptions
		cmp eax, 4
		jne menuLoop
	endMain:
	mov esp, ebp
	pop ebp
	ret

; printing the string
PrintString:
	push ebp
	mov ebp, esp
	mov eax, 4
	mov ebx, 1
	mov ecx, [ebp + 8]	
	mov edx, [ebp + 12]
	int 0x80	
	mov esp, ebp
	pop ebp
	retn 8

;reading andd opening the directory
ReadAndOpen:
	push ebp
	mov ebp, esp
	; open(".")
	mov eax, 5
	mov ebx, dirPath
	mov ecx, 0
	mov edx, 0
	int 0x80
	mov [fd], eax 
	call BlueColorMode

	;reading directory 
	readLoop:
		mov eax, 220
		mov ebx, [fd]
		mov ecx, buffer
		mov edx, 1024
		int 0x80
		test eax, eax
		jle endRead
		mov edi, buffer; the buffer
		mov esi, eax ;bytes that were read
		parsingEntries:
			;going until all the bytes that were read are 0
			cmp esi, 0
			jle readLoop

			lea ebx, [edi + 18]
			push esi
			push edi
			mov edi, ebx
			mov ecx, 0
			call Strlen
			push eax
			push ebx
			call PrintString
			;call ResetColorMode
			call PrintNewLine
			pop edi
			pop esi
			movzx eax, word [edi + 16]
			add edi, eax
			sub esi, eax
			jmp parsingEntries
	endRead:
		call ResetColorMode
		mov esp, ebp
		pop ebp
		ret

Strlen:
	push ebp
	mov ebp, esp
	strlenLoop:
		cmp byte [edi], 0 ; if you want to use you must send the string address to edi
		je strlenEnd
		inc edi
		inc ecx
		jmp strlenLoop
	strlenEnd:
	mov eax, ecx
	mov esp, ebp
	pop ebp
	ret

SwitchOptions:
	push ebp
	mov ebp, esp
	mov eax, [ebp + 8]
	cmp eax, '1'
	je printDir
	cmp eax, '3'
	je changeDir
	cmp eax, '2'
	je readFile
	cmp eax, '4'
	je quitOption

	jmp switchEnd
	readFile:
		call ReadFromFile
		jmp switchEnd
	changeDir:
		call ChangeDirectory
		jmp switchEnd

	printDir:
		push lenList
		push listDir
		call PrintString
		call ReadAndOpen
		jmp switchEnd

	quitOption:
		push lenEnd
		push endOption
		call PrintString
		mov eax, 4
	switchEnd:
		mov esp, ebp
		pop ebp
		retn 4

PickOption:
    push ebp
    mov ebp, esp

    mov eax, 3      
    mov ebx, 0        
    mov ecx, inputBuffer 
    mov edx, 1      	
    int 0x80      
    mov al, [inputBuffer] 
	push eax
	; removing the \n
    mov eax, 3	
    mov ebx, 0
    mov ecx, inputBuffer
    mov edx, 1
    int 0x80 
	pop eax

	mov esp, ebp
    pop ebp
    ret

ChangeDirectory:
    push ebp
    mov ebp, esp

    push lenDirExplanation
    push dirExplanation
    call PrintString

    mov eax, 3
    mov ebx, 0
    mov ecx, dirPath
    mov edx, 256
    int 0x80

    test eax, eax           
    jle endChange          

    mov ebx, dirPath
    dec eax                 
    add ebx, eax           
    mov byte [ebx], 0      

    mov eax, 12            
    mov ebx, dirPath
    int 0x80
    cmp eax, 0
    jl changeDirError     

    mov byte [dirPath], '.'
    mov byte [dirPath + 1], 0
    jmp endChange

    changeDirError:
		push lenDirError
		push dirError
		call PrintString
		mov byte [dirPath], '.'
		mov byte [dirPath + 1], 0

    endChange: 
        mov esp, ebp
        pop ebp
        ret

PrintNewLine:
    push ebp
    mov ebp, esp
    mov eax, 4
	mov ebx, 1
	mov ecx, newLine
	mov edx, 1
	int 0x80
	mov esp, ebp
    pop ebp
    ret

;changes the color to blue for the text
BlueColorMode:
	push ebp
    mov ebp, esp
	pusha ; must push causes problems
	mov eax, 4
	mov ebx, 1
	mov ecx, blueColor
	mov edx, blueLen
	int 0x80
	popa
	mov esp, ebp
    pop ebp
    ret

ResetColorMode:
	push ebp
    mov ebp, esp
	pusha ;it fixed a bug that sometimes this function crashed everything don't know why but i fixed it by saving the registers in the stack
	mov eax, 4
	mov ebx, 1
	mov ecx, resetColor
	mov edx, resetLen
	int 0x80
	popa
	mov esp, ebp
    pop ebp
    ret

ReadFromFile:
    push ebp
    mov ebp, esp

    mov eax, 3
    mov ebx, 0
    mov ecx, fileName
    mov edx, 256
    int 0x80
    
    ; remove newline from filename
    test eax, eax
    jle endReadFile
    mov ebx, fileName
    dec eax
    add ebx, eax
    mov byte [ebx], 0       ;Replace \n with null terminator

    ;Opn the file
    mov eax, 5              ; sys_open
    mov ebx, fileName
    mov ecx, 0              ;readonly
    int 0x80
    cmp eax, 0
    jl fileError            ;Check for error
    mov ebx, eax            ; Save file descriptor

    ;read the file
    mov eax, 3              ; sys_read
    mov ecx, fileBuffer
    mov edx, 4096
    int 0x80
    
    push eax                ;Save bytes read
    push ebx                ;Save file descriptor

    ;close the file
    mov eax, 6              ;sys close
    int 0x80

    ;print the file contents
    pop ebx                 ;Restore (not needed but for stack balance)
    pop edx                 ;Get bytes read as length
    
    test edx, edx
    jle endReadFile         ;if nothing read, exit
    
    mov eax, 4              ;write
    mov ebx, 1              ;stdout
    mov ecx, fileBuffer
    ;edx already has the length
    int 0x80
    
    call PrintNewLine
    jmp endReadFile

    fileError:
    ;Print error message (you can add an error message in .data section)
    ;For now, just exit
    
    endReadFile:
    mov esp, ebp
    pop ebp
    ret