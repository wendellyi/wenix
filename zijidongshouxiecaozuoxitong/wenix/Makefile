all:
	cd boot && make && cd ..
	cd kernel && make && cd ..
	dd of=os.img if=boot/boot.bin bs=512 count=1
	dd of=os.img if=boot/loader.bin bs=512 seek=1
	dd of=os.img if=kernel/kernel.bin bs=512 seek=32