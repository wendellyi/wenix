org 0x7c00

bottom_of_stack equ 0x7c00

jmp short LABEL_START
nop

bs_oem_name:            db 'wenix os'           ; 必须8个字节
bpb_bytes_per_sec:      dw 512                  ; 每个扇区的字节数
bpb_sec_per_clus:       db 1                    ; 每个簇族的扇区数量
bpb_sec_by_boot:        dw 1                    ; boot记录占的扇区数量
bpb_count_of_fat:       db 2                    ; fat表的数量
bpb_files_of_root:      dw 224                  ; 根目录文件最大数量
bpb_count_of_sec:       dw 2880                 ; 逻辑扇区总数
bpb_media:              db 0xf0                 ; 介质类型
bpb_sec_per_fat:        dw 9                    ; 每个fat的扇区数量
bpb_sec_per_track:      dw 18                   ; 每磁道扇区数
bpb_count_of_header:    dw 2                    ; 磁头数量（面数）
bpb_sec_of_hidden:      dd 0                    ; 隐藏扇区数量
bpb_count_of_sec32:     dd 0                    ; bpb_count_of_sec为0，逻辑扇区数量由此值记录
bs_driver_number:       db 0                    ; int 0x13的驱动器号
bs_reserved1:           db 0                    ; 未使用
bs_boot_ex_flag:        db 0x29                 ; 扩展引导标记（0x29）
bs_vol_id:              dd 0                    ; 卷序号
bs_vol_lab:             db 'wenix os fs'        ; 卷标识，必须11个字节
bs_file_sys_type:       db 'FAT12      '        ; 文件系统类型，必须8个字节

LABEL_START:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, bottom_of_stack
    
    mov ax, boot_msg
    call strlen
    mov ax, boot_msg
    call print_msg
    jmp $
    
strlen:
    mov bx, ax
    mov word [msg_len], 0
.loop:    
    mov al, [bx]
    cmp al, 0
    jz .done
    inc word [msg_len]
    inc bx
    jmp .loop
.done
    ret
    
print_msg:
	mov bp, ax
	mov cx, [msg_len]
	mov ax, 0x1301
	mov bx, 0x000c
    mov dh, 0
	mov dl, 0
	int 0x10
	ret
    
; 变量
sec_of_root_dir: dw 14                      ; 根目录占用的扇区数量
sec_number: dw 0                            ; 要读取的扇区号
odd_or_even: db 0                           ; 奇数还是偶数
name_of_loader: db 'loader bin', 0          ; loader.bin的文件名
msg_len: dw 0
boot_msg: db 'booting ......', 0            ; 定长，有必要吗？
ok_msg: db   'loader ok ......', 0
err_msg: db  'no loader!', 0

times 510-($-$$) db 0
dw 0xaa55