org 0x7c00
jmp LABEL_START

sec_number equ 155              ; 字符串存储的逻辑扇区号
buffer_base equ 0x9000
buffer_offset equ 0x1000
bpb_sec_per_track:  dd 0x0018
bs_driver_number:   db 0
str_len:            dw 0
test_string:        db 'Hello World', 0

buffer: times 128  db 0

LABEL_START:
    mov ax, cs
    mov ds, ax
    mov ss, ax
    mov sp, 0x7c00

    mov es, ax
    mov bp, test_string
    call print_msg

    mov bx, buffer_offset
    mov ax, buffer_base
    mov es, ax
    mov ax, sec_number
    mov cl, 1
    call read_sector
    mov bp, buffer_offset
    mov ax, buffer_base
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

;; ax存放逻辑扇区号，es:bx为内存地址
read_sector:
    push bp
    mov bp, sp
    sub esp, 2
    
    mov byte [bp-2], cl              ; 开辟2个字节存放要读取的扇区数量
    push bx
    mov bl, [bpb_sec_per_track]
    div bl
    inc ah                           ; 扇区号
    mov cl, ah                       ; 扇区号放在cl中
    mov dh, al
    shr al, 1                        ; 柱面号
    mov ch, al                       ; 柱面号放在ch中
    and dh, 1                        ; 磁头号
    pop bx
    
    mov dl, [bs_driver_number]       ; 驱动器编号
.go_on_reading:
    mov ah, 2                        ; 功能号将磁盘内容读到内存中
    mov al, byte [bp-2]              ; 扇区数量
    int 0x13
    jc .go_on_reading                ; 进位表示出错
    
    add esp, 2
    pop bp
    ret

times 510-($-$$) db 0
dw 0xaa55