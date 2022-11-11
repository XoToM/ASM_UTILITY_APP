%ifndef __STD
%define __STD 1

section .bss
	heap resd 0

section .text
	extern _ExitProcess@4
	extern _GetLastError@0
	extern _GetProcessHeap@0
	extern _HeapAlloc@12
	extern _HeapFree@12
	extern _HeapReAlloc@16

	global malloc
	global mfree
	global mrealloc
	global mresize
	
	__init__:
		call _GetProcessHeap@0
		mov [heap], eax

		call __init_stdio__

		ret

	malloc:						;	Allocate memory on the heap. EAX indicates the size (in bytes). The new pointer is returned in EAX.
			push edx
			push ecx
			push eax				;	Store the size of the allocated memory for later. Adjust the size of the allocation to include the allocation size

			add eax, 4
			push eax
			push dword 8
			push dword [heap]
			call _HeapAlloc@12		;	Allocate the memory on the heap

			cmp eax, 0
			jnz .return

			call _GetLastError@0	;	In case of an error get the error code and shutdown the program.
			push eax
			call _ExitProcess@4
			ret

		.return:
			pop dword [eax]				;	Store the size of the allocation in the first 4 bytes of the allocation, then move the memory pointer by 4 bytes forward. Return the new pointer
			add eax, 4
			pop ecx
			pop edx
			ret


	mfree:						;	Frees allocated memory. EAX stores pointer to said memory.
			push edx
			push ecx
			sub eax, 4
			push eax
			push dword 0
			push dword [heap]
			call _HeapFree@12		;	Free up the allocated memory

			cmp eax, 0
			jnz .return

			call _GetLastError@0	;	In case of an error get the error code and shutdown the program.
			push eax
			call _ExitProcess@4

		.return:
			mov eax, 0
			pop ecx
			pop edx
			ret

	mresize:					;	Resizes	the memory at EAX by at least EDX bytes. If EDX is negative acts as NOP. Stores the new pointer in EAX, and the new size in EDX
			cmp edx, 0
			jz .exit
			jns .work
		.exit:
			ret
		.work:
			push eax
			add edx, [eax-4]
			mov eax, edx
			shr eax, 1
			add edx, eax
			pop eax
			;	Let the execution continue into mrealloc
	mrealloc:					;	Reallocates a memory block, changing its size. Pointer to the memory is stored in EAX, the new size is in EDX. The new pointer is stored in EAX. EDX remains unchanged.
			push edx
			push ecx
			sub eax, 4
			add edx, 4

			push edx
			push eax
			push dword 8
			push dword [heap]
			call _HeapReAlloc@16		;	Reallocate the memory

			cmp eax, 0

			jnz .return


			call _GetLastError@0	;	In case of an error get the error code and shutdown the program.
			push eax
			call _ExitProcess@4
			ret

		.return:
			sub edx, 4
			mov dword [eax], edx			;	Update the size
			add eax, 4						;	Offset the pointer and return
			pop ecx
			pop edx
			ret

	msize:						;	Get the size of the memory block stored at EAX (not including memsizecounter). Stores the result in EAX. Pointer in EAX is not preserved nor is the memory freed, and should be copied before calling this.
			mov eax, dword [eax-4]
			ret

	proc_exit:
			push eax
			call _ExitProcess@4
			ret

%endif