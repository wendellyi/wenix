current_dir=$(shell pwd)
obj_name=boot
all: $(obj_name).asm
	nasm $(obj_name).asm -o $(obj_name).bin
	dd of=wenix.img if=boot.bin bs=512 count=1
	yes | mv wenix.img ../../