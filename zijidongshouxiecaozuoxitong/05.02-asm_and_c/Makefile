all: bar.c foo.asm
	nasm -f elf foo.asm -o foo.o
	gcc -c bar.c
	ld -s foo.o bar.o -o asm_c