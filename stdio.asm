%ifndef __STD_IO
%define __STD_IO 1

%ifndef __STD
	%include "std.asm"
%endif

section .data
	global stdout
	global stdin
	written dd 0
	stdout dd 0
	stdin dd 0

section .text
	extern _GetStdHandle@4
	extern _WriteConsoleA@20

	global cout
	global __init_stdio__

	__init_stdio__:
				;Set up the handles for the standard Input and Output
			push dword -11
			call _GetStdHandle@4
			mov [stdout], eax

			push dword -10
			call _GetStdHandle@4
			mov [stdin], eax
			ret

	cout:				;	Prints out the string located at ECX. Registers
			push edx
			push ecx
			push eax
			push 0
			push written
			push dword [eax]
			add eax, 4
			push eax
			push dword [stdout]
			call _WriteConsoleA@20

			cmp eax, 0
			jnz .return
			call _GetLastError@0	;	In case of an error get the error code and shutdown the program.
			push eax
			call _ExitProcess@4
			ret

		.return:
			pop eax
			pop ecx
			pop edx
			ret

%endif