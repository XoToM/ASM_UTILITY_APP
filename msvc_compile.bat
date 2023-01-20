"..\..\nasm\nasm" -f win32 -o prog.obj source.asm
link prog.obj /subsystem:console /entry:main /out:program.exe /defaultlib:kernel32.lib
program.exe
echo %ERRORLEVEL%