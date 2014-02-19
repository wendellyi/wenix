org 0x7c00

bottom_of_stack equ 0x7c00
base_of_loader equ 0x9000           ; loader.bin被加载的段地址
offset_of_loader equ 0x0100         ; loader.bin被加载的偏移地址
sec_count_of_root_dir equ 14        ; 根目录条目占用的扇区数

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
    
    ; 复位软驱
    xor ah, ah
    xor dl, dl
    int 0x13
    
    mov word [sec_number], start_sec_of_root_dir      ; 根目录占用的扇区数量
LABEL_SEARCH_ROOT_DIR_BEGIN:
    cmp word [root_dir_loop_counter], 0
    jz LABEL_NO_LOADER                                  ; 没有找到loader
    dec word [root_dir_loop_counter]
    
    ; 读取一个扇区到内存
    mov ax, base_of_loader
    mov es, ax
    mov bx, offset_of_loader
    mov ax, [sec_number]
    mov cl, 1
    call read_sector
    
    ; 获取字符串长度
    mov ax, name_of_loader
    call strlen
    mov dx, [str_len]
    mov si, name_of_loader          ; ds:si -> "loader bin"
    mov di, offset_of_loader        ; es:di -> base_of_loader:0x0100
    cld
    mov dx, 0x10                    ; 每个扇区的条目数量为16个
    
LABEL_SEARCH_LOADER:
    cmp dx, 0                       ; 循环计数器
    jz LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR
    dec dx
    mov cx, 11                      ; 文件名必须是11字节
LABEL_CMP_FILE_NAME:
    cmp cx, 0
    jz LABEL_FILE_NAME_FOUND
    dec cx
    lodsb
    cmp al, byte [es:di]
    jz LABEL_GO_ON                  ; 相等则继续比较
    jmp LABEL_DIFFERENT             ; 出现了差异
    
LABEL_GO_ON:
    inc di                          ; 增加比较目标的偏移
    jmp LABEL_CMP_FILE_NAME         ; 继续比较
    
LABEL_DIFFERENT:
    and di, 0xffe0                  ; 每个条目占32个字节
    add di, 0x20                    ; 这两条语句作用是让es:di指向下一条目
    mov si, name_of_loader
    jmp LABEL_SEARCH_LOADER
    
LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
    inc word [sec_number]
    jmp LABEL_SEARCH_ROOT_DIR_BEGIN
    

    
LABEL_NO_LOADER:
    mov ax, err_msg
    call print_msg   
    jmp $
    
strlen:
    mov bx, ax
    mov word [str_len], 0
.loop:    
    mov al, [bx]
    cmp al, 0
    jz .done
    inc word [strlen]
    inc bx
    jmp .loop
.done:
    ret
    
print_msg:
    mov bp, ax
    call strlen
	mov cx, [str_len]
	mov ax, 0x1301
	mov bx, 0x000c
    mov dh, 0
	mov dl, 0
	int 0x10
	ret
; 从此处开始加载loader
; fat表占9个扇区，那么有512*9/1.5=307条目
; 根目录栈14个扇区
; 而且得到处簇号是相对于数据区的
; 而且0号和1号簇无效，2号簇代表数据区第一个扇区（簇族）
; 文件的扇区号=1（引导区）+18（fat表）+14（根目录）+簇号-2
LABEL_FILE_NAME_FOUND:
    mov ax, sec_count_of_root_dir
    and di, 0xffe0                  ; 从当前条目开始
    add di, 0x1a                    ; 直接偏移到文件首簇号
    mov cx, word [es:di]          ; 得到这个值
    push cx                         ; 将簇号存放在栈上
    add cx, ax
    add cx, delta_sec_number        ; cx现在就是文件的扇区号
    mov ax, base_of_loader
    mov es, ax
    mov bx, offset_of_loader        ; es:bx文件加载地址
    mov ax, cx
    
; ax文件扇区号
; es:bx文件的加载地址
LABEL_GO_ON_LOADING_FILE:
    push ax
    push bx
    mov ah, 0x0e
    mov al, '.'
    mov bl, 0x0f
    int 0x10
    
    ; 将扇区一个一个读取出来
    pop bx
    pop ax
    mov cl, 1
    call read_sector
    pop ax                      ; 将簇号从栈中读出
    call get_fat_entry
    cmp ax, 0x0fff              ; 最后一个簇
    jz LABEL_FILE_LOADED        ; 加载完成
    push ax
    
    ; 下面三条语句计算簇对应的逻辑扇区号
    mov dx, sec_count_of_root_dir
    add ax, dx
    add ax, delta_sec_number
    add bx, [bpb_bytes_per_sec] ; bx需要增加一个扇区的偏移读取下个扇区
    jmp LABEL_GO_ON_LOADING_FILE
LABEL_FILE_LOADED:
    mov ax, ok_msg
    call print_msg
    jmp $
    jmp base_of_loader:offset_of_loader
  
; 变量
sec_number: dw 0                            ; 要读取的逻辑扇区号
start_sec_of_root_dir equ 19                ; 根目录起始扇区号
; 从根目录的第一个扇区到引导扇区有19个扇区，即偏移19
;
delta_sec_number equ 17;    bpb_sec_by_boot+(bpb_count_of_fat*bpb_sec_per_fat)-2
sec_of_root_dir: dw 14                      ; 根目录占用的扇区数量
sec_number_of_fat1 equ 1
root_dir_loop_counter: dw sec_count_of_root_dir ; 读取根目录扇区循环计数变量
odd_or_even: db 0                           ; 奇数还是偶数
name_of_loader: db 'loader  bin'            ; loader.bin的文件名
str_len: dw 0
boot_msg: db 'booting ......', 0            ; 定长，有必要吗？
ok_msg: db   'loader ok ......', 0
err_msg: db  'no loader!', 0

; 由逻辑扇区号得到chs参数
; 数据在磁盘上存放顺序如下：
; 0面 0磁道 1扇区
; 0面 0磁道 2扇区
; ...
; 0面 0磁道 18扇区
; 1面 0磁道 1扇区
; 1面 0磁道 2扇区
; ...
; 1面 0磁道 18扇区
; 0面 1磁道 1扇区
; 0面 1磁道 2扇区
; ...
; 0面 1磁道 18扇区
; 1面 1磁道 1扇区
; 1面 1磁道 2扇区
; ...
; 1面 1磁道 18扇区
; ...
; 逻辑扇区号是从0开始的，而chs参数扇区号是从1开始的

; ax存放逻辑扇区号，es:bx为存放数据的地址
read_sector:
    push bp
    mov bp, sp
    sub esp, 2
    
    mov byte [bp-2], cl             ; 开辟2个字节存放要读取的扇区数量
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
    mov ah, 2                         ; 功能号将磁盘内容读到内存中
    mov al, byte [bp-2]             ; 扇区数量
    int 0x13
    jc .go_on_reading               ; 进位表示出错
    
    add esp, 2
    pop bp
    ret
    
; 簇号存放在ax中
get_fat_entry:
    push es
    push bx
    push ax
    mov ax, base_of_loader
    sub ax, 0x1000              ; 在base_of_loader之前空出4k空间存放fat
    mov es, ax
    pop ax
    ; 下面这样写得理由是每个fat表项占3/2个字节
    mov byte [is_odd], 0  
    mov bx, 3
    mul bx
    mov bx, 2
    div bx
    cmp dx, 0                   ; 是否被整除
    jz LABEL_EVEN               ; 整除表明了起始字节数是整的，而不是办个
    mov byte [is_odd], 1        ; ax存放商，dx存放余数
LABEL_EVEN:
    ; 现在ax中存放的是fat表中偏移的字节数
    xor dx, dx
    mov bx, [bpb_bytes_per_sec]     ; 所以现在需要得到扇区偏移数
    div bx                          ; ax存放商，dx存放余数
                                    ; ax中是扇区偏移值，dx中是余下的字节数
                                    ; 即扇区内偏移
    push dx
    mov bx, 0
    add ax, sec_number_of_fat1     ; fat1的起始扇区号
    mov cl, 2                       ; 读取两个
    call read_sector                ; 读取fat表
    pop dx
    add bx, dx
    mov ax, [es:bx]                 ; 刚好可以读到此fat表项
    cmp byte [is_odd], 1            ; 如果是为奇数，那么取高四位
                                      ; 为整个表项的第四位，右移四位
    jnz LABEL_EVEN_2
    shr ax, 4
LABEL_EVEN_2:
    and ax, 0x0fff                  ; 如果是偶数就happy了
                                    ; 直接读入两个字节，然后取低12位
                                    ; ax就含有簇号对应的值
    
LABEL_GET_FAT_ENTRY_OK:
    pop bx
    pop es
    ret

times 510-($-$$) db 0
dw 0xaa55