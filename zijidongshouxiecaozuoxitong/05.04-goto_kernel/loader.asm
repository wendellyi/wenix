;; loader的主要功能是：
;; 1.将系统的内存信息在实模式下读取出来
;; 2.在实模式下将kernel加载到指定的地址中
;; 3.进入保护模式
;; 4.将内存的信息显示出来
;; 5.开启分页
;; 6.将kernel的代码移动到正确的地方，然后跳转到kernel中

jmp LABEL_START

%include "pm.inc"           ; 与保护模式相关的宏
%include "loader.inc"       ; 与loader相关的宏

LABEL_GDT:              DESCRIPTOR 0, 0, 0
LABEL_DESC_FLAT_CODE:   DESCRIPTOR 0, 0xffffff, DA_CR|DA_32|DA_LIMIT_4K
LABEL_DESC_FLAT_RW:     DESCRIPTOR 0, 0xffffff, DA_DRW|DA_32|DA_LIMIT_4K
LABEL_DESC_VIDEO:       DESCRIPTOR 0xb8000, 0xffff, DA_DRW|DA_DPL3

gdt_len equ $-LABEL_GDT         ; gdt长度
gdt_ptr dw gdt_len-1            ; gdt段界限
        dd logic_addr_of_loader+LABEL_GDT ; 段基址
        
selector_flat_code equ LABEL_DESC_FLAT_CODE-LABEL_GDT
selector_flat_rw equ LABEL_DESC_FLAT_RW-LABEL_GDT
selector_video equ LABEL_DESC_VIDEO-LABEL_GDT

LABEL_START:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, rm_bottom_of_stack
    
    ; 复位软驱
    xor ah, ah
    xor dl, dl
    int 0x13

    mov ax, base_of_kernel
    mov es, ax
    mov bx, offset_of_kernel
    mov ax, kernel_start_sec_number
    mov cx, kernel_sec_count
.loop:
    cmp cx, 0
    jz LABEL_LOADED
    push cx
    push ax

    mov cl, 1
    call read_sector
    pop ax
    inc ax
    add bx, 512
    pop cx
    dec cx
    jmp .loop

LABEL_LOADED:   
    mov bp, offset_of_kernel
    mov ax, base_of_kernel
    mov es, ax
    call print_msg

    mov bp, boot_msg
    mov ax, cs
    mov es, ax
    call print_msg

    jmp $
    
;; es:bp存放字符串的地址
strlen:
    push bx
    mov bx, bp
    mov word [str_len], 0
.loop:    
    mov al, [es:bx]
    cmp al, 0
    jz .done
    inc word [str_len]
    inc bx
    jmp .loop
.done:
    pop bx
    ret

;; es:bp存放字符串
print_msg:
    push cx
    push bx
    push dx
    call strlen
    mov cx, [str_len]
    mov ax, 0x1301
    mov bx, 0x000c
    mov dh, 0
    mov dl, 0
    int 0x10
    pop dx
    pop bx
    pop cx
    ret
    
; 逻辑扇区号是从0开始的，而chs参数扇区号是从1开始的
; ax存放逻辑扇区号，es:bx为存放数据的地址, cl存放扇区的数量
read_sector:
    push bp
    mov bp, sp
    sub esp, 2
    
    mov byte [bp-2], cl              ; 开辟2个字节存放要读取的扇区数量
    push bx
    mov bl, 18
    div bl
    inc ah                           ; 扇区号
    mov cl, ah                       ; 扇区号放在cl中
    mov dh, al
    shr al, 1                        ; 柱面号
    mov ch, al                       ; 柱面号放在ch中
    and dh, 1                        ; 磁头号
    pop bx
    
    mov dl, 0                        ; 驱动器编号
.go_on_reading:
    mov ah, 2                        ; 功能号将磁盘内容读到内存中
    mov al, byte [bp-2]              ; 扇区数量
    int 0x13
    jc .go_on_reading                ; 进位表示出错
    
    add esp, 2
    pop bp
    ret
[section .data]
align 32
[bits 32]
LABEL_DATA:
_pm_msg: db "in protect mode now ...", 0x0a, 0x0a, 0
_mem_chk_title: db "base_addr_low base_addr_hig length_low length_hig type", 0x0a, 0
_ram_size_prifix: db "ram size: ", 0
_return_string: db 0x0a, 0

_sp_in_real_mode: dw 0
_mem_chk_result: dd 0
_display_position: dd (80*6+0)*2            ; 显示信息的位置
_mem_size: dd 0
_ard_struct:
    _base_addr_low: dd 0
    _base_addr_hig: dd 0
    _length_low: dd 0
    _length_hig: dd 0
    _ard_type: dd 0
ard_struct_size equ $-_ard_struct
    
_mem_chk_buffer: times 256 db 0

pm_msg equ _pm_msg-$$
mem_chk_title equ logic_addr_of_loader+_mem_chk_title
ram_size_prefix equ logic_addr_of_loader+_ram_size_prifix
return_string equ logic_addr_of_loader+_return_string
display_position equ logic_addr_of_loader+_display_position
mem_size equ logic_addr_of_loader+_mem_size
mem_chk_result equ logic_addr_of_loader+_mem_chk_result
ard_struct equ logic_addr_of_loader+_ard_struct
    base_addr_low equ logic_addr_of_loader+_base_addr_low
    base_addr_hig equ logic_addr_of_loader+_base_addr_hig
    length_low equ logic_addr_of_loader+_length_low
    length_hig equ logic_addr_of_loader+_length_hig
    ard_type equ logic_addr_of_loader+_ard_type
mem_chk_buffer equ logic_addr_of_loader+_mem_chk_buffer

pm_stack:   times 0x1000 db 0
bottom_of_stack equ logic_addr_of_loader+$