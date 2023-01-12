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

	;global cout
	;global __init_stdio__

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
			call handleerror

		.return:
			pop eax
			pop ecx
			pop edx
			ret

extern _ReadFile@20


	stream_read:			;	EAX stores pointer to str, EBX stores stream handle, EDX stores max byte count (or 0)
			push ecx
			push ebx

			push eax
			push 0
			mov ecx, esp

			cmp edx, 0
			jnz .mbytes
			mov edx, dword [eax-4]
			sub edx, 4
		.mbytes:

			push 0
			push ecx
			push edx
			add eax, 4
			push eax
			push ebx
			call _ReadFile@20

			cmp eax, 0
			jnz .exit
			call handleerror
		.exit:

			pop ecx
			pop eax

			mov dword [eax], ecx

			pop ebx
			pop ecx
			ret


	cin:				;	reading from stdin while its in line mode appears to add in an endl at the end of the input
			push ebx
			mov ebx, dword [stdin]
			call stream_read
			pop ebx
			ret

%endif