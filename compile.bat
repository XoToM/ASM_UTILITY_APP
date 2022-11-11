nasm -f win32 -gdwarf -o prog.obj source.asm
link prog.obj /subsystem:console /debug /entry:main /out:program.exe /defaultlib:kernel32.lib
program.exe
echo %ERRORLEVEL%