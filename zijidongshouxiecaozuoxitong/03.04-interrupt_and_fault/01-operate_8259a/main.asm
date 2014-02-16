%include "../../pm.inc"

page_dir_base0 equ 0x200000      ; 2M
page_tab_base0 equ 0x201000      ; 2M + 4K
page_dir_base1 equ 0x210000      ; 2M + 64K
page_tab_base1 equ 0x211000      ; 2M + 64K + 4K

linear_addr_demo equ 0x00401000
code_foo_dst equ 0x00401000
code_bar_dst equ 0x00501000
code_do_paging_demo_dst equ 0x00301000

jmp LABEL_BEGIN                 ; 直接跳转到开始处

[SECTION .gdt]
LABEL_GDT:              DESCRIPTOR 0, 0, 0
LABEL_DESC_CODE32:      DESCRIPTOR 0, seg_code32_len-1, DA_CR+DA_32 
    ; 后面有代码把这个段的选择子赋值到ds中，
    ; 如果没有使用DA_CR会导致保护异常，这个代码段还有可读的属性
LABEL_DESC_DATA:        DESCRIPTOR 0, data_len-1, DA_DRW
LABEL_DESC_STACK:       DESCRIPTOR 0, bottom_of_stack, DA_DRWA+DA_32
LABEL_DESC_VIDEO:       DESCRIPTOR 0xb8000, 0xffff, DA_DRW+DA_DPL3
LABEL_DESC_FLAT_CODE:   DESCRIPTOR 0, 0xfffff, DA_CR | DA_32 | DA_LIMIT_4K
    ; 0~4G，代码段的属性千万不要搞错了
LABEL_DESC_FLAT_RW:     DESCRIPTOR 0, 0xfffff, DA_DRW | DA_LIMIT_4K
    ; 0~4G，数据段的属性也不要弄错了

gdt_len equ $-LABEL_GDT
gdt_ptr:    dw gdt_len-1
            dd 0

selector_code32 equ LABEL_DESC_CODE32-LABEL_GDT
selector_data equ LABEL_DESC_DATA-LABEL_GDT
selector_stack equ LABEL_DESC_STACK-LABEL_GDT
selector_video equ LABEL_DESC_VIDEO-LABEL_GDT
selector_flat_code equ LABEL_DESC_FLAT_CODE-LABEL_GDT
selector_flat_rw equ LABEL_DESC_FLAT_RW-LABEL_GDT

[SECTION .data]
ALIGN 32
[BITS 32]
LABEL_DATA:
_pm_msg: db "in protect mode now ...", 0x0a, 0x0a, 0
_mem_chk_title: db "base_addr_low base_addr_hig length_low length_hig type", 0x0a, 0
_ram_size_prifix: db "ram size: ", 0
_return_string: db 0x0a, 0

_sp_in_real_mode: dw 0
_mem_chk_result: dd 0
_display_position: dd (80*3+0)*2            ; 显示信息的位置
_mem_size: dd 0
_ard_struct:
    _base_addr_low: dd 0
    _base_addr_hig: dd 0
    _length_low: dd 0
    _length_hig: dd 0
    _ard_type: dd 0
ard_struct_size equ $-_ard_struct
_page_tab_count: dd 0
    
_mem_chk_buffer: times 256 db 0

pm_msg equ _pm_msg-$$
mem_chk_title equ _mem_chk_title-$$
ram_size_prefix equ _ram_size_prifix-$$
return_string equ _return_string-$$
display_position equ _display_position-$$
mem_size equ _mem_size-$$
mem_chk_result equ _mem_chk_result-$$
ard_struct equ _ard_struct-$$
    base_addr_low equ _base_addr_low-$$
    base_addr_hig equ _base_addr_hig-$$
    length_low equ _length_low-$$
    length_hig equ _length_hig-$$
    ard_type equ _ard_type-$$
page_tab_count equ _page_tab_count-$$
mem_chk_buffer equ _mem_chk_buffer-$$
data_len equ $-LABEL_DATA

[SECTION .idt]
ALIGN 32
[BITS 32]
LABEL_IDT:
%rep 0x20
    GATE selector_code32, spurious_handler, 0, DA_386_INT_GATE
%endrep
.0x21 GATE selector_code32, clock_handler, 0, DA_386_INT_GATE
%rep (0x81-0x22)
    GATE selector_code32, spurious_handler, 0, DA_386_INT_GATE
%endrep
.0x81: GATE selector_code32, int_0x80_handler, 0, DA_386_INT_GATE
%rep (0xff-0x81)
    GATE selector_code32, spurious_handler, 0, DA_386_INT_GATE
%endrep

idt_len equ $-LABEL_IDT
idt_ptr dw idt_len-1
        dd 0

[SECTION .gs]
ALIGN 32
[BITS 32]
LABEL_STACK:
times 512 db 0

bottom_of_stack equ $-LABEL_STACK-1

[SECTION .s16]
[BITS 16]
LABEL_BEGIN:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ax, 0x4000                       ; 实模式把栈段设置成这个值安全
    mov ss, ax
    mov sp, 0x1000
    
    ; 获取内存信息，现在是在实模式下
    mov ebx, 0
    mov di, _mem_chk_buffer
.loop:    
    mov eax, 0xe820
    mov ecx, ard_struct_size
    mov edx, 0x534d4150
    int 0x15
    jc LABEL_MEM_CHK_FAILED         ; 有进位，表示出错了
    add di, ard_struct_size
    inc dword [_mem_chk_result]
    cmp ebx, 0                     ; 判断有无后续数据需要处理
    jne .loop
    jmp LABEL_MEM_CHK_OK
LABEL_MEM_CHK_FAILED:
    mov dword [_mem_chk_result], 0
LABEL_MEM_CHK_OK:
    
    ; 在实模式下初始化所有描述符
    INIT_DESCRIPTOR LABEL_DESC_CODE32, LABEL_SEG_CODE32
    INIT_DESCRIPTOR LABEL_DESC_DATA, LABEL_DATA
    INIT_DESCRIPTOR LABEL_DESC_STACK, LABEL_STACK
    
    ; 准备载入gdt
    xor eax, eax
    mov ax, ds
    shl eax, 4
    add eax, LABEL_GDT
    mov dword [gdt_ptr+2], eax
    
    ; 准备载入idt
    xor eax, eax
    mov ax, ds
    shl eax, 4
    add eax, LABEL_IDT
    mov dword [idt_ptr+2], eax
    
    lgdt [gdt_ptr]
    cli
    
    lidt [idt_ptr]
    
    in al, 0x92
    or al, 0x02
    out 0x92, al
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp word selector_code32:0
    
[SECTION .s32]
[BITS 32]
LABEL_SEG_CODE32:
    mov ax, selector_data
    mov ds, ax
    mov es, ax
    mov ax, selector_video
    mov gs, ax
    mov ax, selector_stack
    mov ss, ax
    mov esp, bottom_of_stack
    
    call INIT_8259A
    int 0x80
    
    ; 显示进入保护模式信息
    push pm_msg
    call display_string
    add esp, 4
    
    ; 显示表头
    push mem_chk_title
    call display_string
    add esp, 4
    
    ; 显示内存分布信息
    call display_mem_size
    call code_paging_demo
    
    sti
    jmp $

; 初始化8259芯片    
INIT_8259A:
    mov al, 0x11            ; 00010001
    out 0x20, al            ; 主8259，ICW1
    call io_delay
    
    out 0xa0, al            ; 从8259，ICW1
    call io_delay
    
    ; ICW2写入时会设置中断号与管脚的对应关系
    mov al, 0x20            ; IRQ0对应中断向量0x20
    out 0x21, al            ; 主8259，ICW2
    call io_delay
    
    mov al, 0x28            ; IRQ8对应中断向量0x28
    out 0xa1, al            ; 从8259，ICW2
    call io_delay
    
    ; 从主块上说明级联关系
    mov al, 0x04            ; IR2级联了从块
    out 0x21, al            ; 主8259，ICW3
    call io_delay
    
    ; 从从块上说明级联关系
    mov al, 0x02            ; 级联在主块的IR2上
    out 0xa1, al            ; 从8259，ICW3
    call io_delay
    
    mov al, 0x01            ; 主8259，ICW4
    out 0x21, al
    call io_delay
    
    out 0xa1, al            ; 从8259，ICW4
    call io_delay
    
    mov al, 0xfe            ; 仅仅开启主块的定时器中断
    ; mov al, 0xff          ; 屏蔽主8259所有的中断
    out 0x21, al            ; 主8259，OCW1
    call io_delay
    
    mov al, 0xfe            ; 屏蔽从8259所有中断
    out 0xa1, al            ; 从8259，OCW1
    call io_delay
    
    ret
    
; 使用4条空指令
io_delay:
    nop
    nop
    nop
    nop
    ret
    
_spurious_handler:
spurious_handler equ _spurious_handler-$$
    mov ah, 0x0c
    mov al, '!'
    mov [gs:((80*0+75)*2)], ax
    iretd
    
_int_0x80_handler:
int_0x80_handler equ _int_0x80_handler-$$
    mov ah, 0x0c
    mov al, '8'
    mov [gs:((80*0+60)*2)], ax
    mov al, '0'
    mov [gs:((80*0+61)*2)], ax
    iretd
    
_clock_handler:
clock_handler equ _clock_handler-$$
    mov ecx, 0xfffffff              ; 采用死循环延时
    loop $
    
    mov ah, 0x0c
    mov al, [gs:((80*0+70)*2)]
    cmp al, 'A'
    jz .BA
    
.AB
    mov al, 'A'
    mov [gs:((80*0+70)*2)], ax
    mov al, 'B'
    mov [gs:((80*0+71)*2)], ax
    jmp .done
.BA
    mov al, 'B'
    mov [gs:((80*0+70)*2)], ax
    mov al, 'A'
    mov [gs:((80*0+71)*2)], ax

.done
    mov al, 0x20
    out 0x20, al                        ; 发送eoi
    iretd
    
; 启动分页机制，注意这个地方先初始化一次页表，而且后面还要初始化  
start_paging:    
    ; 根据内存大小计算需要初始化的页目录数目和页表数目
    xor edx, edx
    mov eax, [mem_size]
    mov ebx, 0x400000       ; 一个页表能表示4M的内存
    div ebx
    mov ecx, eax            ; eax为商
    test edx, edx           ; 判断是否有余数
    inc ecx
.no_remainder:
    mov [page_tab_count], ecx          ; 暂存页表个数，便于后面使用
    
    ; 所有现行地址对应物理地址，并不考虑内存空洞
    ; 首先初始化页目录
    mov ax, selector_flat_rw
    mov es, ax
    mov edi, page_dir_base0
    xor eax, eax
    mov eax, page_tab_base0 | PG_P | PG_USU | PG_RWW ; 注意页表开始的地方是写死的
.1:
    stosd
    add eax, 4096   ; 下一个页表
    loop .1
    
    ; 再初始化所有页表
    mov eax, [page_tab_count]
    mov ebx, 1024                   ; 一个页表占用一页的空间，含有1024页信息
    mul ebx                         ; 得到页的个数
    mov ecx, eax
    mov edi, page_tab_base0
    xor eax, eax
    mov eax, PG_P | PG_USU | PG_RWW
.2:
    stosd
    add eax, 4096                   ; 每个页4K
    loop .2
    
    mov eax, page_dir_base0
    mov cr3, eax
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax                    ; 开启分页
    jmp short .3
.3:
    nop
    ret                             ; 开启分页结束
    
display_mem_size:
    push esi
    push edi
    push ecx
    
    mov esi, mem_chk_buffer
    mov ecx, [mem_chk_result]               ; 读取数据结构的个数
.loop:
    mov edx, 5                              ; 内存信息数据结构有5个字段
    mov edi, ard_struct                     ; 同一结构体反复使用
.1:
    push dword [esi]
    call display_int
    pop eax
    stosd                                   ; stosd dword ptr es:[edi], eax
    add esi, 4
    dec edx
    cmp edx, 0
    jnz .1
    call display_return
    cmp dword [ard_type], 1                 ; 判断是否能被OS使用 cmp dword ptr ds:[], 1
    jne .2                                   ; 直接continue，不参与计算
    mov eax, [base_addr_low]
    add eax, [length_low]
    cmp eax, [mem_size]

    jb .2
    mov [mem_size], eax
    
.2:
    loop .loop
    
    call display_return
    
    push ram_size_prefix
    call display_string
    add esp, 4
    
    push dword [mem_size]
    call display_int
    add esp, 4
    
    pop ecx
    pop edi
    pop esi
    ret
    
; 对分页机制进行测试
code_paging_demo:
    mov ax, cs
    mov ds, ax
    mov ax, selector_flat_rw
    mov es, ax

    ; C语言的默认压栈方式，从右向左
    ; 将foo函数的代码加载到指定的内存区域
    push len_code_foo_src
    push offset_code_foo_src
    push code_foo_dst
    call memcpy
    add esp, 12
    
    ; 将bar函数的代码加载到指定的内存区域
    push len_code_bar_src
    push offset_code_bar_src
    push code_bar_dst
    call memcpy
    add esp, 12
    
    push len_code_do_paging_demo
    push offset_code_do_paging_demo
    push code_do_paging_demo_dst
    call memcpy
    add esp, 12
    
    mov ax, selector_data
    mov ds, ax
    mov es, ax
    
    call start_paging
    call selector_flat_code:code_do_paging_demo_dst
    call code_paging_switch
    call selector_flat_code:code_do_paging_demo_dst
    
    ret
    
; 切换页目录，使用第二套分页数据
code_paging_switch:
    mov ax, selector_flat_rw
    mov es, ax
    mov edi, page_dir_base1
    xor eax, eax
    mov eax, page_tab_base1 | PG_P | PG_USU | PG_RWW
    mov ecx, [page_tab_count]
.1:
    stosd
    add eax, 4096
    loop .1
    
    mov eax, [page_tab_count]
    mov ebx, 1024
    mul ebx
    mov ecx, eax
    mov edi, page_tab_base1
    xor eax, eax
    mov eax, PG_P | PG_USU | PG_RWW
.2:
    stosd
    add eax, 4096
    loop .2
    
    ; 假设内存大于8M
    ; 32位线性地址由10位页表索引+10位页索引+12位页内偏移
    mov eax, linear_addr_demo
    shr eax, 22                ; 得到页表索引
    mov ebx, 4096              ; 页表是4K对齐，得到目标页表的偏移地址
                                ; 相对于所有页表基地址的偏移地址
    mul ebx
    mov ecx, eax               ; 将页表首地址放在ecx中
    mov eax, linear_addr_demo  ; 下面是要得到页索引
    shr eax, 12
    and eax, 0x03ff
    mov ebx, 4                  ; 页表中每个表项都是4字节
    mul ebx
    add eax, ecx
    add eax, page_tab_base1      ; 得到目标页表项的物理地址
    mov dword [es:eax], code_bar_dst | PG_P | PG_RWW | PG_RWW
                                ; 上面的操作时修改了此表项内的值（物理页索引）
                                ; 这个地方能够这样修改的原因是先前的线性地址
                                ; 和物理地址是一致，所以讲线性地址当做物理地址
                                ; 访问时没有问题，修改后则不然了
    mov eax, page_dir_base1
    mov cr3, eax
    jmp short .3
.3:
    nop
    ret    

; 要用到的过程
code_do_paging_demo:
offset_code_do_paging_demo equ code_do_paging_demo-$$
    mov eax, linear_addr_demo
    call eax
    retf
len_code_do_paging_demo equ $-code_do_paging_demo

code_foo_src:
offset_code_foo_src equ code_foo_src-$$
    mov ah, 0x0c
    mov al, 'f'
    mov [gs:((80*22+0)*2)], ax
    mov al, 'o'
    mov [gs:((80*22+1)*2)], ax
    mov [gs:((80*22+2)*2)], ax
    ret
len_code_foo_src equ $-code_foo_src

code_bar_src:
offset_code_bar_src equ code_bar_src-$$
    mov ah, 0x0c
    mov al, 'b'
    mov [gs:((80*23+0)*2)], ax
    mov al, 'a'
    mov [gs:((80*23+1)*2)], ax
    mov al, 'r'
    mov [gs:((80*23+2)*2)], ax
    ret
len_code_bar_src equ $-code_bar_src
    
%include "lib.inc"
    
seg_code32_len equ $-LABEL_SEG_CODE32