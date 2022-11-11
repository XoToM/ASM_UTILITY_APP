%ifndef __STD_STRING
%define __STD_STRING 1

%include "std.asm"
%include "stdio.asm"

%macro defString 1+
	dd %%endtext - %%starttext
	%%starttext: db %1
	%%endtext: db 0
%endmacro

section .data
	db "-"
	CONST_NUMERICS defString{"0123456789ABCDEF"}
	endl defString{0xd,0xa}

section .text
	snew:					;	Creates a new string and initializes its contents to the string stored in EAX. Stores the pointer to the new string in EAX. If EAX is null creates a string with capacity of 50 bytes.
			cmp eax, 0
			jnz .sized
			mov eax, 54
			call malloc
			ret
		.sized:
			push ecx
			push edx

			mov esi, eax

			mov eax, dword [eax]

			add eax, 4
			mov ecx, eax
			shr eax, 1
			add eax, ecx

			push ecx
			call malloc
			pop ecx

			mov edi, eax
			push eax
			cld


			rep
			movsb					;	 Access Violation exception - Wrong counting direction?, Wrong Pointers?	;0xC0000005

			pop eax
			pop edx
			pop ecx
			ret



	sappend:					;	Appends the string in EDX to the string in EAX. Returns the new string
			push ecx
			push edx
			push eax

			mov edx, [edx]
			add edx, [eax]
			add edx, 4
			sub edx, [eax - 4]

			pop eax
			call mresize
			pop edx

			mov edi, eax
			add edi, 4
			add edi, [eax]
			mov ecx, [edx]
			mov esi, edx
			add esi, 4

			rep
			movsb

			mov ecx, [edx]
			add [eax], ecx

			pop ecx
			ret

	sappend_endl:					;	Appends a new line to the string in EAX. EAX will contain the pointer to the string.
			push edx
			mov edx, endl
			call sappend
			pop edx
			ret
	sappend_int:					;	Append the int in EDX to the string in EAX. EAX will contain the pointer to the string, EDX will remain unchanged
			push edx
			push ecx
			push ebx
			mov ebx, esp

			push dword 0
			mov esi, esp
			push dword 0
			push dword 0
			push dword 0
			push dword 0

			xor edi, edi			;esi - pointer to next character, edi length of the string

			push eax
			push edx

			cmp edx, 0
			jns .unsign
			neg edx
		.unsign:
			mov eax, edx
			mov ecx, 10

		.loop:
			xor edx, edx
			div ecx

			mov dl, byte [edx + CONST_NUMERICS]
			mov byte [esi], dl
			inc edi
			dec esi
			cmp eax, 0
			jnz .loop

			pop edx
			cmp edx, 0
			jns .not_signed
			mov al, byte [CONST_NUMERICS-1]
			mov byte [esi], al
			dec esi
			inc edi

		.not_signed:
			sub esi, 3
			mov dword [esi], edi

			pop eax
			mov edx, esi
			call sappend

			mov esp, ebx
			pop ebx
			pop ecx
			pop edx
			ret
%endif