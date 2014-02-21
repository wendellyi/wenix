obj_name=boot
target=os.img
all: $(obj_name).asm
	nasm $(obj_name).asm -o $(obj_name).bin
	nasm loader.asm -o loader.bin
	dd of=$(target) if=boot.bin bs=512 count=1
	dd of=$(target) if=loader.bin bs=512 seek=1
	yes | mv $(target) ../../