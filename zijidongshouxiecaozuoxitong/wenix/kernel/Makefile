all:
	cd ../lib && make && cd -
	nasm -f elf -o kernel.o kernel.asm
	gcc -c -o start.o start.c -Wall
	ld -m elf_i386 -s -Ttext 0x30400 -o kernel.bin kernel.o ../lib/string.o ../lib/klib.o start.o