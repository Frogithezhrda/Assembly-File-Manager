nasm -f elf32 -o viewer.o fileViewer.asm
ld -m elf_i386 -o viewer viewer.o
./viewer
