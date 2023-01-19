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
		;.nameptr:	0
		dd %1
		;.price:	4
		dd %2
		;.maxcount:	8
		dd %3
		;.count:	12
		dd %3
	%endmacro

	machine_slot_x_address1 defString{"1234"}
	machine_slot_y_address1 defString{"ABCD"}
	machine_slot_x_address2 defString{ 0x31, 0x32, 0x33, 0x34}
	machine_slot_y_address2 defString{ 0x41, 0x42, 0x43, 0x44}


	machine_slots_names:
		.oreo: rawDefString{"Oreo"}
		.pringles: rawDefString{"Pringles"}
		.mars: rawDefString{"Mars"}
		.gbread: rawDefString{"Green bread"}
		
		.water: rawDefString{"Water"}
		.beer: rawDefString{"Beer"}
		.batteries: rawDefString{"AA Batteries"}
		.racoon: rawDefString{"Literally a racoon"}

		.rpaint: rawDefString{"Red Paint"}
		.bpaint: rawDefString{"Blue Paint"}
		.gpaint: rawDefString{"Green Paint"}
		.vmachine: rawDefString{"Vending Machine"}
		
		.tpacket: rawDefString{"Packet of tissues"}
		.myphone: rawDefString{"MyPhone 5 Max"}
		.chalk: rawDefString{"Black chalk"}
		.oxygen: rawDefString{"oxygen gas (container not included)"}
	machine_slots:
		MachineSlotEntry machine_slots_names.oreo, 300, 3
		MachineSlotEntry machine_slots_names.pringles, 250, 1
		MachineSlotEntry machine_slots_names.mars, 100, 1
		MachineSlotEntry machine_slots_names.gbread, 2999, 1

		MachineSlotEntry machine_slots_names.water, 199, 3
		MachineSlotEntry machine_slots_names.beer, 850, 1
		MachineSlotEntry machine_slots_names.batteries, 100, 4
		MachineSlotEntry machine_slots_names.racoon, 0, 1

		MachineSlotEntry machine_slots_names.rpaint, 123, 8
		MachineSlotEntry machine_slots_names.bpaint, 456, 8
		MachineSlotEntry machine_slots_names.gpaint, 789, 8
		MachineSlotEntry machine_slots_names.vmachine, 4242, 1

		MachineSlotEntry machine_slots_names.tpacket, 159, 8
		MachineSlotEntry machine_slots_names.myphone, 99999, 1
		MachineSlotEntry machine_slots_names.chalk, 50, 10
		MachineSlotEntry machine_slots_names.oxygen, 1000, 9999

	machine_slots_end:
	machine_slots_size: dd (machine_slots_end-machine_slots)/16
	console_input_key_event:	;18
		.type:
			dw 0	;	Should be 0x0001 for key event
			dw 0	;	Padding cuz the event union appears to have an alignment of 4
		.keydown:
			dd 0	;	bool
		.repeat:
			dw 0 	;	Number of times this key has been pressed
		.keycode:
			dw 0	;	https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
		.scancode:
			dw 0	;	keyboard generated scan code. Device dependant. Ignore
		.char:
			dw 0	;	Ascii/WideChar character generated by the key press. for ascii only 1 byte is used
		.control_keys:
			dd 0	;	Control Keys pressed with this key.
	dd 0	;	Padding
	dd 0	;	Padding
	console_input_key_event_count:
		dd 0	;	Garbage?
	keypressbuffer:
		dd 0
	coins:
		dd 1
		dd 2
		dd 5

		dd 10
		dd 20
		dd 50

		dd 100
		dd 200
		dd 500

		;dd 1000
		;dd 2000
		;dd 5000
		.end:
		dd 0
		.count:
		dd 9	;	TODO Update the coin count manually
	coin_key_keys:defString{0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39}
	coin_key_symbols: defString{"123456789"}

section .text
extern _ReadConsoleInputA@16

global main

get_keypress:
	push console_input_key_event_count
	push dword 1
	push console_input_key_event
	push dword [stdin]
	call _ReadConsoleInputA@16

	mov edx, eax
	call tryhandleerror
	mov al, [console_input_key_event.keycode]
	ret

test_keypad:
	push eax
	push edx
	push ecx
	enter 4, 0		;	0-EventCountRead
	.get_inp:

	call get_keypress

	xor edx, edx
	mov dx, word [console_input_key_event.type]
	
	cmp dx, 0x0001
	jne .get_inp
	.kev_process:
	mov eax, dword [console_input_key_event.keydown]
	add eax, eax
	jz .get_inp	;If key up then repeat

	getString eax, "Key Down '#' code: "
	call snew

	mov cx, word [console_input_key_event.char]

	mov edx, eax
	add edx, 14
	mov byte [edx], cl

	xor edx, edx
	mov dx, word [console_input_key_event.keycode]
	call sappend_int
	call sappend_endl
	call cout
	call mfree
	jmp .get_inp
	.exit:
	leave
	pop ecx
	pop edx
	pop eax
	ret

do_keypad:	;	Gets item id from user. Returns index to slot in EAX
	push ecx
	mov dword [keypressbuffer], 0
	

	.test_last_key:;	bl = keycount,	 bh = key
		cmp byte [keypressbuffer], 0
		jz .zero_keys

		mov bh, byte [keypressbuffer]

		cmp byte [keypressbuffer+1], 0
		jz .one_key

		.two_keys:
			mov bl, 2
			mov bh, byte [keypressbuffer+1]
			jmp .test_last_key_done
		.one_key:
			mov bl, 1
			mov bh, byte [keypressbuffer]
			jmp .test_last_key_done
		.zero_keys:
			mov bx, 0
			jmp .test_last_key_done

		.test_last_key_done:

	.get_key:
		push ecx
		push EAX

		.get_key_retry:
		push console_input_key_event_count
		push dword 1
		push console_input_key_event
		push dword [stdin]
		call _ReadConsoleInputA@16
		call tryhandleerror

		cmp word [console_input_key_event.type], 0x0001
		jnz .get_key_retry
		cmp dword [console_input_key_event.keydown], 0
		jz .get_key_retry

		.get_key_done:
			pop eax
			pop ecx

	.removekey:
		cmp byte [console_input_key_event.keycode], 0x08
		jne .removekey_done

		push ebx
		push eax
		push edx
		xor edx, edx
		mov dl, bl
		dec dl

		jns .np1
		mov dl, 0
		.np1:
		mov byte [keypressbuffer+edx], 0

		getString eax, 0x08, ' ', 0x08
		call cout
		pop edx
		pop eax
		pop ebx
		;ret
		.removekey_done:


	.addkey:
		push ebx
		push eax
		push edx
		cmp bl, 2
		je .addkey_done

		cmp bh, 0
		jg .xaxis
			.yaxis:
				mov edx, machine_slot_y_address2				;	Compare
				mov al, byte [console_input_key_event.keycode]
				call sfind_char
				cmp eax, -1										;	Check result
				jne .yaxis_yes									;	If found process
				cmp bh, 0										;	If not found check if mode is 0
				je .xaxis										;	If mode 0 go to x axis
				jmp .addkey_done								;	Otherwise exit.
			.yaxis_yes:
				xor edx, edx
				mov dl, byte [machine_slot_y_address1 + 4 + eax]	;	Get the result char from keycode
				xor eax, eax
				call snew										;	Print char in console
				call sappend_char
				call cout
				call mfree
				xor eax, eax
				mov al, dl										;	Store char in eax
				jmp .addkey_write								;	Exit
			.xaxis:
				mov edx, machine_slot_x_address2
				mov al, byte [console_input_key_event.keycode]
				call sfind_char
				cmp eax, -1
				jne .xaxis_yes
				jmp .addkey_done
			.xaxis_yes:
				xor edx, edx
				mov dl, byte [machine_slot_x_address1 + 4 + eax]	;	Get the result char from keycode
				xor eax, eax
				call snew										;	Print char in console
				call sappend_char
				call cout
				call mfree
				xor eax, eax
				mov al, dl										;	Store char in eax
				neg al
				jmp .addkey_write								;	Exit
		.addkey_write:
		;	EAX has ascii char if the keycode is valid, -1 otherwise
			;mov edx, 4
			;sub dl, bl
			xor edx, edx
			mov dl, bl
			mov byte [keypressbuffer+edx], al

		.addkey_done:
		;	EAX has ascii char if the keycode is valid, -1 otherwise
		

		pop edx
		pop eax
		pop ebx

	cmp bl, 2
	jne .test_last_key
	cmp byte [console_input_key_event.keycode], 0x0D
	jne .test_last_key

	push eax
	getString eax, endl
	call cout
	pop eax

	.get_index:
		mov cl, byte [keypressbuffer+1]
		cmp byte [keypressbuffer], cl
		jl .get_index_ls1
		.get_index_gr1:
			mov al, byte [keypressbuffer+1]
			mov ah, byte [keypressbuffer]
			jmp .get_index_dne1
		.get_index_ls1:
			mov al, byte [keypressbuffer]
			mov ah, byte [keypressbuffer+1]
		.get_index_dne1:
			neg al
		call get_slot_by_id
		call print_slot

	;	EAX should still have the slot index by now
	;call marker

	pop ecx
	ret

do_coin_input:	;	Handles Coin Input. EAX contains the price to pay. On return EAX will contain the extra amount
	push edx
	push ecx			;	TODO: DEBUG THIS FUNCTION. There is some WILD memory corruption going on here.
	push ebx
	mov ecx, eax
	xor eax, eax
	call snew			;	EAX contains String Builder, ECX contains total to be payed

	.main_loop:
		mov dword [eax], 0	;	Clear the StringBuilder
		push ecx
		mov ecx, dword [coins.count]
		.loop_display_coins:
			mov edx, ecx
			call sappend_int
			getString edx, ") "
			call sappend
			dec ecx
			pushf
			mov edx, dword [coins + ecx*4]
			call sappend_price
			call sappend_endl
			call cout
			call mfree
			call snew
			popf
			jnz .loop_display_coins
		pop ecx
		getString edx, endl, "You have "
		call sappend
		mov edx, ecx
		call sappend_price
		getString edx, " left to pay. Press enter to cancel the payment, or press one of the numbers above to insert the corresponding coin.", endl
		call sappend
		call cout
		call mfree
		call snew

		.get_key:
			push ecx
			push EAX

			.get_key_retry:
				push console_input_key_event_count
				push dword 1
				push console_input_key_event
				push dword [stdin]
				call _ReadConsoleInputA@16
				call tryhandleerror

				cmp word [console_input_key_event.type], 0x0001
				jnz .get_key_retry
				cmp dword [console_input_key_event.keydown], 0
				jz .get_key_retry

			.get_key_done:
				pop eax
				pop ecx

		cmp byte [console_input_key_event.keycode], 0x0D
		jne .coin_key
		.enter_pressed:
			;	TODO Return all inserted keys here
			jmp .exit

		.coin_key:	;	Read which key was pressed and insert the appropriate coin.
			push eax		;	Look up the key in the key list
			mov edx, coin_key_keys
			mov al, byte[console_input_key_event.keycode]
			call sfind_char
			mov edx, eax
			pop eax

			cmp edx, -1
			je .get_key		;	Wait for another key if its not found

			mov ebx, dword [coins + edx*4]	;	Get the worth of this coin

			mov dword [eax], 0	;	Clear the StringBuilder
			getString edx, "You inserted "
			call sappend
			mov edx, ebx
			call sappend_price
			call sappend_endl
			call cout			;	Print the message to screen

			sub ecx, ebx	;	Subtract the coin from the price
			jg .main_loop	;	If we still need to pay something restart this loop

	call markfree
	call marker
	mov eax, ecx
	jz .exit
	neg eax

	.exit:
	pop ebx
	pop ecx
	pop edx
	ret



get_slot_by_id:		;	Gets machine slot stored in AX and returns an index to slot data in EAX	
	push ecx
	push ebx
	push edx
	mov ebx, eax
	xor eax, eax

	;call marker
	
	mov edx, machine_slot_x_address1
	mov al, bl
	call sfind_char
	mov bl, al
	xor edx, edx
	mov dl, bl
	;call marknum

	mov edx, machine_slot_y_address1
	mov al, bh
	call sfind_char
	mov bh, al
	xor edx, edx
	mov dl, bh
	;call marknum

	xor edx, edx
	mov dl, bh
	sal edx, 2
	add dl, bl
	sal edx, 4

	mov eax, edx
	;call marknum
	pop edx
	pop ebx
	pop ecx
	ret
print_slot:			;	Prints information about item in machine slot. Index in EAX points to slot info
	push ecx
	push eax
	push edx

	mov ecx, eax
	xor eax, eax
	call snew

	mov edx, dword [machine_slots + ecx]
	call sappend
	mov dl, ' '
	call sappend_char
	mov edx, dword [machine_slots+4 + ecx]
	call sappend_price
	getString edx, " x"
	call sappend
	mov edx, dword [machine_slots+12 + ecx]
	call sappend_int
	mov dl, '/'
	call sappend_char
	mov edx, dword [machine_slots+8 + ecx]
	call sappend_int
	call sappend_endl
	call cout
	call mfree

	pop edx
	pop eax
	pop ecx
	ret
print_all_items:
	push eax
	push edx
	push ecx
	getString eax, "We got the following items: ", endl
	call snew

	xor ecx, ecx
	.loop:

	push ebx
	push edx
	push ecx
	xor edx, edx
	


	DIVMOD ecx, dword [machine_slot_x_address1], ebx
	mov dl, byte [machine_slot_y_address1+4 + ecx]
	call sappend_char
	mov dl, byte [machine_slot_x_address1+4 + ebx]
	call sappend_char
	getString edx, " - "
	call sappend
	call cout
	call mfree
	call snew

	pop ecx
	pop edx
	pop ebx

	shl ecx, 1
	mov edx, dword [machine_slots + ecx*8]
	call sappend
	mov dl, ' '
	call sappend_char
	mov edx, dword [machine_slots+4 + ecx*8]
	call sappend_price
	getString edx, " x"
	call sappend
	mov edx, dword [machine_slots+12 + ecx*8]
	call sappend_int
	mov dl, '/'
	call sappend_char
	mov edx, dword [machine_slots+8 + ecx*8]
	call sappend_int
	call sappend_endl
	shr ecx, 1

	inc ecx
	cmp ecx, dword [machine_slots_size]
	jl .loop

	call cout
	;call marknumeax
	call mfree
	;call marker
	pop ecx
	pop edx
	pop eax
	ret

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

marker:
	push eax
	getString eax, "Marker", endl
	call cout
	pop eax
	ret
markfree:
	push eax
	getString eax, "Mark FREE", endl
	call cout
	pop eax
	call mfree
	ret
marknum:
	push eax
	push edx
	mov edx, eax
	xor eax, eax
	call snew
	call sappend_int
	call sappend_endl
	call cout
	call mfree
	pop edx
	pop eax
	ret

	push eax
	getString eax, "Marker", endl
	call cout
	pop eax
	ret
main:

	mov ebp, esp

	call __init__


	mov eax, smsg
	call cout

	getString eax, "Test 1", endl, "Test 2", endl
	call cout
										;	The real program starts

	;mov eax, 0
	getString eax, "The char of the day is '"
	call snew
	mov dl, 'E'
	call sappend_char
	mov dl, "'"
	call sappend_char
	call sappend_endl
	call cout
	call mfree

	sub ebx, esp

	.tttloop: call print_all_items

	call do_keypad		;	INPUT TEST
	;call marknum
	mov eax, dword[machine_slots+4 + eax]
	call do_coin_input

	push eax
	getString eax, "Return: "
	call snew
	pop edx
	call sappend_price
	call sappend_endl
	call cout
	call mfree

	jmp .tttloop

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