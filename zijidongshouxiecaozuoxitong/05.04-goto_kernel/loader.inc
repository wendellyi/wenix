base_of_loader equ 0x9000           ; loader.bin被加载的段地址
offset_of_loader equ 0x0100         ; loader.bin被加载的偏移地址

logic_addr_of_loader equ base_of_loader*0x10        ; loader.bin被加载的逻辑地址

base_of_kernel equ 0x8000           ; 内核被加载的段地址
offset_of_kernel 0x00               ; 内核被加载的偏移地址