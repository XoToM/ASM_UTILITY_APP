%macro defString 1+
.length:
	dd %%endtext - %%starttext
.data:
	%%starttext: db %1
.eof:
	%%endtext: db 0
%endmacro
%macro rawDefString 1+
	dd %%endtext - %%starttext
	%%starttext: db %1
	%%endtext: db 0
%endmacro

%macro getString 2+
	[SECTION .data]
		%%string:
			dd %%endtext - %%starttext
			%%starttext: db %2
			%%endtext: db 0
	__?SECT?__
		mov %1, %%string
%endmacro

%define endl 0xd, 0xa