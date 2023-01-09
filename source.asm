bits 32
default rel

%include "std_string.asm"
%include "stdio.asm"
%include "std.asm"

section .data
	sep defString{", "}

	smsg dd 15
	msg db "Hello, World!", 0xd, 0xa,0



	foo defString{"Foo "}

	bar defString{"Bar", 0xd, 0xa}

	def_ext dd 0

	%macro MachineSlotEntry 3
		.nameptr:
		dd %1
		.price:
		dd %2
		.maxcount:
		dd %3
		.count:
		dd %3
	%endmacro
	
	machine_slots_names:
		.oreo defString{"Oreo"}
		.pringles defString{"Pringles"}
		.mars defString{"Mars"}
		.gbread defString{"Green bread"}
	machine_slots:
	.a1: MachineSlotEntry machine_slots_names.oreo, 200
	.a2: MachineSlotEntry machine_slots_names.pringles, 250
	
	.b1: MachineSlotEntry machine_slots_names.mars, 100
	.b2: MachineSlotEntry machine_slots_names.gbread, 2999


section .text
global main


sappend_price:	;	Appends the price in EDX to the string in EAX. Both EDX and EAX remain unchanged
	push ebx
	push ecx
	push edx

	mov ebx, edx
	
	mov ecx, 100
	DIVMOD ebx, ecx, ecx

	getString edx, 156
	call sappend

	mov edx, ebx
	call sappend_int

	mov edx, ecx
	add edx, 100
	call sappend_int

	mov edx, eax
	add edx, dword [eax]
	add edx, 1
	mov byte [edx], '.' 

	pop edx
	pop ecx
	pop ebx
	ret
displaycoins:


testallansi:
	getString eax, "ANSI Test"
	call snew
	call cout
	mov edx, 0
.loop:
	mov dword [eax], 0
	call sappend_int
	
	push edx
	getString edx, " = w"
	call sappend
	pop edx

	mov ecx, eax
	add ecx, dword [eax]
	add ecx, 3
	mov byte [ecx], dl
	call sappend_endl
	call cout
	inc dx
	cmp dl, 0
	jne .loop
	call mfree
	getString eax, "Test"
	ret

main:

	call __init__


	mov eax, smsg
	call cout

	getString eax, "Test 1", endl, "Test 2", endl
	call cout
										;	The real program starts

	mov eax, 0
	mov ebx, esp
	mov eax, 0
	call snew
	call cout

	sub ebx, esp

	getString eax, "Stack offset: "
	call snew
	mov edx, ebx
	call sappend_int
	call sappend_endl
	call cout

	mov eax, smsg

	call snew
	call cout

	mov eax, foo
	call snew

	mov edx, bar
	call sappend

	mov edx, foo
	call sappend

	mov edx, -1234
	call sappend_int
	call sappend_endl

	call cout

										;	Sample fibonacci sequence (up to 99999)
	mov ecx, 0
	mov ebx, 1
	mov edx, 1

.fib_loop:
	mov dword [eax], 0		;	Clear the string
	push edx
	mov edx, ebx
	inc ebx
	call sappend_int
	getString edx, "	=> "
	call sappend
	pop edx
	call sappend_int
	call sappend_endl
	call cout

	mov edi, edx
	mov edx, ecx
	mov ecx, edi
	add edx, ecx

	cmp edx,  999999999
	jl .fib_loop

	call mfree

	getString eax, "Input some text: "
	call cout

	mov eax, 0
	call snew

	mov edx, 0
	call cin			

	mov edx, eax
	push edx
	getString eax, endl, "You typed in: "
	call snew
	call sappend
	call sappend_endl
	call cout
	
	pop edx
	push edx
	getString eax, "It is "
	call snew
	mov edx, [edx]
	call sappend_int
	getString edx, " bytes long.", endl
	call sappend
	call cout
	

	pop edx

	mov al, 'a'
	call sfind_char
	cmp eax, dword -1

	je .notfound
.found:
	mov edx, eax
	getString eax, "There is an 'a' in the string at position "
	call snew
	call sappend_int
	call sappend_endl
	call cout
	jmp .fexit
.notfound:
	getString eax, "There is no 'a' in this string.", endl
	call cout
.fexit:

	getString eax, "Test: "
	call snew
	mov edx, 90100

	call sappend_price
	call cout

	;call testallansi	;	Display all ANSI characters and their codes

	;Return a successfull exit code and exit
	push dword 0;123456789
	call _ExitProcess@4