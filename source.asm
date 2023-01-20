bits 32
default rel

%include "std_string.asm"
%include "stdio.asm"
%include "std.asm"

section .data

	%macro MachineSlotEntry 3	;	Macro for easier defining of items in the machine. The first macro argument is the pointer to the name string, the second is the item's price, and the third is the max amount of this item that can be in stock at any given time.
		;.nameptr:	0
		dd %1
		;.price:	4
		dd %2
		;.maxcount:	8
		dd %3
		;.count:	12
		dd %3
	%endmacro

	machine_slot_x_address1 defString{"1234"}					;	Number key symbols and their matching keyboard key codes
	machine_slot_x_address2 defString{ 0x31, 0x32, 0x33, 0x34}

	machine_slot_y_address1 defString{"ABCD"}					;	Letter key symbols and their matching keyboard key codes
	machine_slot_y_address2 defString{ 0x41, 0x42, 0x43, 0x44}


	machine_slots_names:					;	Strings used for names for items in each machine slot.
		;	Row 1
		.oreo: rawDefString{"Oreo"}				
		.pringles: rawDefString{"Pringles"}
		.mars: rawDefString{"Mars"}
		.gbread: rawDefString{"Green bread"}
		;	Row 2
		.water: rawDefString{"Water"}
		.beer: rawDefString{"Beer"}
		.batteries: rawDefString{"AA Batteries"}
		.racoon: rawDefString{"Literally a racoon"}
		;	Row 3
		.rpaint: rawDefString{"Red Paint"}
		.bpaint: rawDefString{"Blue Paint"}
		.gpaint: rawDefString{"Green Paint"}
		.vmachine: rawDefString{"Vending Machine"}
		;	Row 4
		.tpacket: rawDefString{"Packet of tissues"}
		.myphone: rawDefString{"MyPhone 5 Max"}
		.chalk: rawDefString{"Black chalk"}
		.oxygen: rawDefString{"oxygen gas (container not included)"}
	machine_slots:							;	Definitions of items in each slot of the vending machine.
		;	Row 1
		MachineSlotEntry machine_slots_names.oreo, 300, 3
		MachineSlotEntry machine_slots_names.pringles, 250, 1
		MachineSlotEntry machine_slots_names.mars, 100, 1
		MachineSlotEntry machine_slots_names.gbread, 2999, 1
		;	Row 2
		MachineSlotEntry machine_slots_names.water, 199, 3
		MachineSlotEntry machine_slots_names.beer, 850, 1
		MachineSlotEntry machine_slots_names.batteries, 100, 4
		MachineSlotEntry machine_slots_names.racoon, 1, 1
		;	Row 3
		MachineSlotEntry machine_slots_names.rpaint, 123, 8
		MachineSlotEntry machine_slots_names.bpaint, 456, 8
		MachineSlotEntry machine_slots_names.gpaint, 789, 8
		MachineSlotEntry machine_slots_names.vmachine, 4242, 1
		;	Row 4
		MachineSlotEntry machine_slots_names.tpacket, 159, 8
		MachineSlotEntry machine_slots_names.myphone, 99999, 1
		;MachineSlotEntry machine_slots_names.chalk, 50, 10
		MachineSlotEntry 0, 0, 0
		MachineSlotEntry machine_slots_names.oxygen, 1000, 9999
		machine_slots_end:	;	Label used to calculate the number of items
		machine_slots_size: dd (machine_slots_end-machine_slots)/16		;	The number of items this machine has. All the items in here will be displayed. Set all fields (including name pointer) to 0 to make the slot empty.

	console_input_key_event:	;	Used for reading keyboard keys
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
		console_input_key_event_count:	;	Number of key events read. Needed, but ignored by the program
			dd 0	;	Garbage data
	keypressbuffer:	dd 0	;	Buffer for the keys pressed on the vending machine's keypad.

	coins:		;	All coins the machine accepts (Listed below as coin values)
		dd 1
		dd 2
		dd 5

		dd 10
		dd 20
		dd 50

		dd 100
		dd 200
		dd 500
					;	These lines can be uncommented to allow banknotes
		;dd 1000
		;dd 2000
		;dd 5000
		.end:
		dd 0
		.count:
		dd 9	;	Replace with "dd 12" to allow for banknotes

	;	Add 3 extra key codes and their symbols to the 2 string definitions below to allow banknotes
	coin_key_symbols: defString{"123456789"}	;	Symbols of keys for inserting coins
	coin_key_keys: defString{0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39}	;	Key codes of keys for inserting coins

section .text
extern _ReadConsoleInputA@16

global main


do_keypad:	;	Gets item id from user. Returns index to slot in EAX or -1 if cancelled
	push ecx

	mov dword [keypressbuffer], 0	;	Reset the key buffer


	.test_last_key:;	Check how many keys have been pressed, and what keys have been entered		bl = keycount,	 bh = key
		cmp byte [keypressbuffer], 0
		jz .zero_keys

		mov bh, byte [keypressbuffer]

		cmp byte [keypressbuffer+1], 0
		jz .one_key

		.two_keys:	;	2 Keys have been pressed
			mov bl, 2
			mov bh, byte [keypressbuffer+1]
			jmp .test_last_key_done
		.one_key:	;	1 Key has been pressed
			mov bl, 1
			mov bh, byte [keypressbuffer]
			jmp .test_last_key_done
		.zero_keys:	;	0 Keys have been pressed
			mov bx, 0
			jmp .test_last_key_done

		.test_last_key_done:

	.get_key:	;	Read 1 key press
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

	.removekey:	;	Check if the key is a backspace, and if so remove 1 key from the key buffer. 
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

	.utility_keys:
		.utility_key_quit:		;	Check if the ESC key has been pressed, if so then exit
			cmp byte [console_input_key_event.keycode], 0x1B
			jne .utility_key_restock
			xor eax, eax
			call proc_exit
		.utility_key_restock:	;	Check if the R key has been pressed, if so then restock the machine
			cmp byte [console_input_key_event.keycode], 0x52
			jne .utility_keys_done
			call restock_machine
			pop ecx
			mov eax, -1
			ret
		.utility_keys_done:

	.addkey:	;	Add the keypress to the key buffer and print it to the console
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

	cmp bl, 2	;	Check if there are exactly 2 keys in the buffer. If there are then that means a valid item code has been entered
	jne .test_last_key
	cmp byte [console_input_key_event.keycode], 0x0D	;	Only proceed if the enter key has been pressed
	jne .test_last_key

	push eax
	getString eax, endl
	call cout
	pop eax

	.get_index:	;	Convert the item code to an item index
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

	call print_slot	;	Print the selected item to the console

	;	EAX should still have the slot index by now

	pop ecx
	ret

do_coin_input:	;	Handles Coin Input. EAX contains the price to pay. On return EAX will contain the extra amount
	push edx
	push ecx
	push ebx
	mov ecx, eax
	xor eax, eax
	call snew			;	EAX contains String Builder, ECX contains total to be payed, EDI contains a copy of ECX which is used for returning coins
	mov edi, ecx

	.main_loop:
		;	Display all coins this machine accepts
		mov dword [eax], 0	;	Clear the StringBuilder
		push edi
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
		pop edi

		;	Tell the user how much they still have to pay
		push edi
		getString edx, endl, "You have "
		call sappend
		mov edx, ecx
		call sappend_price
		getString edx, " left to pay. Press enter to cancel the payment, or press one of the numbers above to insert the corresponding coin.", endl, endl
		call sappend
		call cout
		call mfree
		call snew

		;	Wait for a keypress
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
		pop edi

		cmp byte [console_input_key_event.keycode], 0x0D	;	Check what key has been [ressed]
		jne .coin_key
		.enter_pressed:	;	Enter has been pressed, so the user wants to cancel the transaction
			call mfree

			getString eax, "Cancelled transaction", endl
			call cout			;	Print a message

			mov eax, edi		;	If the user canceled the transaction return the amount the user inserted
			sub eax, ecx
			call do_coin_return	;	Return the inserted amount

			mov eax, -1		;	Return -1 to indicate that the operation was cancelled
			jmp .exit

		.coin_key:	;	Read which key was pressed and insert the appropriate coin.
			push edi
			push eax		;	Look up the key in the key list
			mov edx, coin_key_keys
			mov al, byte[console_input_key_event.keycode]
			call sfind_char
			mov edx, eax
			pop eax

			cmp edx, -1
			je .get_key		;	Wait for another key if its not found. EDI should still be on top of the stack

			mov ebx, dword [coins + edx*4]	;	Get the worth of this coin

			mov dword [eax], 0	;	Clear the StringBuilder
			getString edx, "You inserted "
			call sappend
			mov edx, ebx
			call sappend_price
			call sappend_endl
			call cout			;	Print the message to screen

			sub ecx, ebx	;	Subtract the coin from the price
			pop edi
			jg .main_loop	;	If we still need to pay something restart this loop
	.loop_exit:
	call mfree
	
	mov eax, ecx
	cmp eax, 0
	jz .exit
	neg eax

	.exit:
	pop ebx
	pop ecx
	pop edx
	ret

do_coin_return:	;	Returns the amount specified in EAX as coins (printing to console). If EAX is 0 this acts as NOP
	push eax
	push edx
	push ecx
	push ebx
	push edi

	mov edi, dword [coins.count]
	.main_loop:
		cmp eax, 0
		jz .exit

		dec edi							;	Get the next coin (descending in value)
		mov ebx, eax
		DIVIDE ebx, dword[coins+edi*4]	;	Check how many of this coin fit in the current amount
		cmp ebx, 0
		jz .print_end					;	If 0 then we can skip the printing

		push eax						;	Print out how many coins just got dispensed
		push edi
		getString eax, "You got "
		call snew
		mov edx, ebx
		call sappend_int
		getString edx, " x "
		call sappend
		pop edi
		mov edx, dword[coins+edi*4]
		push edi
		call sappend_price
		call sappend_endl
		call cout
		call mfree
		pop edi
		pop eax

		.print_end:
		MULTIPLY ebx, dword[coins+edi*4]		;	Subtract the dispensed coins from the total
		sub eax, ebx
	
	cmp edi, 0				;	If we ran out of coins we cna dispense we can safely exit the loop
	jg .main_loop


	.exit:
	pop edi
	pop ebx
	pop ecx
	pop edx
	pop eax
	ret

restock_machine:	;	Restock all slots of the machine
	mov ecx, dword[machine_slots_size]
	dec ecx
	.loop:				;	Iterate throuhg all the slots and reset the current item count to its maximum value
		shl ecx, 1
		mov eax, dword[machine_slots+8+ecx*8]
		mov dword[machine_slots+12+ecx*8], eax
		shr ecx, 1
		dec ecx
		jns .loop
	getString eax, "Machine has been restocked.", endl		;	Print a message then exit
	call cout
	ret

get_slot_by_id:		;	Gets machine slot stored in AX and returns an index to slot data in EAX
	push ecx
	push ebx
	push edx
	mov ebx, eax
	xor eax, eax


	mov edx, machine_slot_x_address1	;	Get the column of the item
	mov al, bl
	call sfind_char
	mov bl, al
	xor edx, edx
	mov dl, bl

	mov edx, machine_slot_y_address1	;	Get the row of the item
	mov al, bh
	call sfind_char
	mov bh, al
	xor edx, edx
	mov dl, bh

	xor edx, edx					;	Do some basic maths to convert the row and column into an index into the slot table
	mov dl, bh
	sal edx, 2
	add dl, bl
	sal edx, 4

	mov eax, edx

	pop edx
	pop ebx
	pop ecx
	ret
print_slot:			;	Prints information about item in machine slot. Index in EAX points to slot info
	push ecx
	push eax
	push edx

	mov ecx, eax

	cmp dword [machine_slots + ecx], 0	;	If the slot is empty we can skip it
	je .exit

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

	.exit:
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
		push ebx		;	Check if the slot is empty, skip it if it is
		mov ebx, ecx
		shl ebx, 1
		cmp dword [machine_slots + ebx*8], 0
		pop ebx
		je .skip_slot

		push ebx		;	Print out all the information about the slot in a readable way
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
		.skip_slot:	;	Increment the slot number
		inc ecx
	cmp ecx, dword [machine_slots_size]	;	If we looped through all slots we can exit
	jl .loop

	call cout
	call mfree
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

wait_key:
	.get_key:
			push ecx
			push eax

			.get_key_retry:
				push console_input_key_event_count	;	Wait for a console event
				push dword 1
				push console_input_key_event
				push dword [stdin]
				call _ReadConsoleInputA@16
				call tryhandleerror

				cmp word [console_input_key_event.type], 0x0001		;	If the event is not a key event or of its an event for lifting the key we should wait for 1 more event
				jnz .get_key_retry
				cmp dword [console_input_key_event.keydown], 0	
				jz .get_key_retry

			.get_key_done:
				pop eax
				pop ecx
	ret

main:
	mov ebp, esp			;	Initialize the stack, the IO and the Heap
	call __init__


	.main_loop: call print_all_items			;	Print all items to the user

	getString eax, "Press ESC to exit, R to restock, or type in an item code above to buy an item.", endl
	call cout			;	Tell the user how to use this program

	call do_keypad		;	Get an item code from the user
	cmp eax, -1
	je .next_iter		;	If the user did not input an item code we restart this loop
	mov ebx, eax

	cmp dword[machine_slots+12+ebx], 0
	jle .out_of_stock						;	Check if the requested item is in stock

	mov eax, dword[machine_slots+4 + ebx]
	call do_coin_input						;	Wait for the user to pay for the item

	cmp eax, -1
	je .next_iter						;	Check if the user cancelled the transaction

	mov edx, eax

	push eax
	push edx
	getString eax, "You got "			;	Tell the user that they got the item
	call snew
	mov edx, dword[machine_slots + ebx]
	call sappend
	call sappend_endl
	call cout
	call mfree
	pop edx
	pop eax

	dec dword[machine_slots+12+ebx]		;	Decrement the amount of this item that is in stock

	call do_coin_return					;	Give back change to the user

	.next_iter:						;	Wait for a key press from the user then restart this loop
	call wait_key
	jmp .main_loop

	.out_of_stock:			;	Print out a message informing the user the requested item is not in stock
		getString eax, "Sorry, this item is out of stock.", endl
		call cout
		jmp .next_iter	;	Restart the loop

	;Return a successfull exit code and exit (unreachable, but better safe than sorry)
	push dword 0;123456789
	call _ExitProcess@4