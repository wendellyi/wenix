current_dir=$(shell pwd)
obj_name=main

all: $(obj_name).asm
	nasm $(obj_name).asm -o $(obj_name).bin
	cd ../../bootloader && make && yes | mv bootloader.bin $(current_dir)
	cd $(current_dir)
	dd of=wenix.img if=bootloader.bin bs=512 count=1
	dd of=wenix.img if=$(obj_name).bin bs=512 seek=1
	yes | mv wenix.img ../../