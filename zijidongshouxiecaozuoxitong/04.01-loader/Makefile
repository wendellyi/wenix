current_dir=$(shell pwd)
obj_name=boot
target=os.img
all: $(obj_name).asm
	nasm $(obj_name).asm -o $(obj_name).bin
	dd of=$(target) if=boot.bin bs=512 count=1
	yes | mv $(target) ../../
    
test:
	nasm test.asm -o test.bin
	dd of=wenix.img if=test.bin bs=512 count=1
	dd of=wenix.img if=string.bin bs=512 seek=155
	yes | mv wenix.img ../../