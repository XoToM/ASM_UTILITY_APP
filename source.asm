bits 32
default rel

%include "std_string.asm"

section .data
	sep dd 2
	db ", "

	smsg dd 15
	msg db "Hello, World!", 0xd, 0xa,0


	foo defString{"Foo "}

	bar defString{"Bar", 0xd, 0xa}

	dd 12
	marker_msg db "Marker Hit", 0xd, 0xa
	dd 14
	marker1_msg db "Marker 1 Hit", 0xd, 0xa
	dd 14
	marker2_msg db "Marker 2 Hit", 0xd, 0xa

	def_ext dd 0

section .text
global main










handleerror:
	call _GetLastError@0	;	Get the error code
	push eax

	call _ExitProcess@4

marker:
	push eax
	push ecx
	push edx
	push 0
	push written
	push dword [marker_msg-4]
	push marker_msg
	push dword [stdout]
	call _WriteConsoleA@20
	pop edx
	pop ecx
	pop eax
	ret
marker1:
	push eax
	push ecx
	push edx
	push 0
	push written
	push dword [marker1_msg-4]
	push marker1_msg
	push dword [stdout]
	call _WriteConsoleA@20
	pop edx
	pop ecx
	pop eax
	ret
marker2:
	push eax
	push ecx
	push edx
	push 0
	push written
	push dword [marker2_msg-4]
	push marker2_msg
	push dword [stdout]
	call _WriteConsoleA@20
	pop edx
	pop ecx
	pop eax
	ret


main:

	call __init__


	mov eax, smsg
	call cout


										;	The real program starts

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
	mov edx, sep
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


	;Return the exit code and exit
	mov eax, dword [def_ext]
	push eax
	call _ExitProcess@4