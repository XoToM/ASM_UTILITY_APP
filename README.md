# Assembly Utility App
 
A simple vending machine program written in assembly.
This version is different from the c++ version. It doesn't use any c/c++ standard library funcions, instead I wrote replacement functions for performing basic tasks.
These functions probably use different win32 functions than the ones in the c/c++ standard library, meaning that this app differs quite a bit from my c++ version of the utility app.

## Compilation
You need to have NASM installed to compile this program. https://www.nasm.us/

compile.bat compiles the program with a GNU Linker. It assumes nasm is added to the PATH environment variable, and that LD is installed in "C:\Program Files (x86)\SASM\MinGW\mingw32\bin\ld.exe". The arguments passed in during compilation and linking allow this program to be debugged with the GDB debugger.

msvc_compile.bat compiles the program with the Visual Studio msvc linker. It assumes that the script is ran via the Visual Studio developer console, and that the NASM installation directory is stored in the parent of this project's folder.
