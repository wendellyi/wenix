jmp LABEL_START

%include "../pm.inc"
%include "loader.inc"

LABEL_GDT:              DESCRIPTOR 0, 0, 0
LABEL_DESC_FLAT_CODE:   DESCRIPTOR 0, 0xffffff, DA_CR|DA_32|DA_LIMIT_4K
LABEL_DESC_FLAT_RW:     DESCRIPTOR 0, 0xffffff, DA_DRW|DA_32|DA_LIMIT_4K
LABEL_DESC_VIDEO:       DESCRIPTOR 0xb8000, 0xffff, DA_DRW|DA_DPL3

gdt_len equ $-LABEL_GDT
gdt_ptr dw gdt_len-1
        dd logic_addr_of_loader+LABEL_GDT
        
selector_flat_code equ LABEL_DESC_FLAT_CODE-LABEL_GDT
selector_flat_rw equ LABEL_DESC_FLAT_RW-LABEL_GDT
selector_video equ LABEL_DESC_VIDEO-LABEL_GDT

kernel_start_sec_number equ 5               ; 内核模块从洛基山区号为5的地方开始读入
bottom_of_stack equ 0x9500
kernel_sec_count equ 4

boot_msg:   db 'kernel loaded ......', 0
str_len:    dw 0

LABEL_START:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, ax
    
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