nasm -gcv8 -F cv8 -f win32 -o prog.obj source.asm
"C:\Program Files (x86)\SASM\MinGW\mingw32\bin\ld.exe" prog.obj -o program.exe -e main -g -lkernel32
program.exe
echo %ERRORLEVEL%