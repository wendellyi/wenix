all:
	nasm -f elf -o kernel.o kernel.asm
	ld -m elf_i386 -s -Ttext 0x30400 -o kernel.bin kernel.o