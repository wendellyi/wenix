; 下面的程序完成了如下功能
; 创建两个特权级，0和3，程序开始时在特权级0，而后转移到特权级3中，在特权级3中，
; 通过0x80中断。而中断0x80完成的内容是向屏幕中央输出80字样，并返回特权级为3的
; 代码中。
; 另外通过调用门实现了从特权级为3的代码向特权级为0的代码中转移，饭后返回
; 主要涉及的内容有，gdt，idt，调用门，中断门，tss，dpl，cpl和rpl

%include "../../pm.inc"

jmp LABEL_BEGIN

[SECTION .gdt]
LABEL_GDT:                  DESCRIPTOR 0, 0, 0
LABEL_DESC_RING0_CODE:      DESCRIPTOR 0, seg_ring0_code_len-1, DA_CR|DA_32
LABEL_DESC_RING3_CODE:      DESCRIPTOR 0, seg_ring3_code_len-1, DA_CR|DA_32|DA_DPL3
LABEL_DESC_RING0_STACK:     DESCRIPTOR 0, bottom_of_ring0_stack, DA_DRW|DA_32
LABEL_DESC_RING3_STACK:     DESCRIPTOR 0, bottom_of_ring3_stack, DA_DRW|DA_32| DA_DPL3
LABEL_DESC_CALL_GATE_CODE:  DESCRIPTOR 0, seg_call_gate_code_len-1, DA_C|DA_32
LABEL_DESC_VIDEO:           DESCRIPTOR 0xb8000, 0xffff, DA_DRW | DA_DPL3
LABEL_DESC_TSS:             DESCRIPTOR 0, seg_tss_len-1, DA_386TSS
LABEL_CALL_GATE:            GATE selector_call_gate_code, 0, 0, DA_386CALLGATE|DA_DPL3

gdt_len equ $-LABEL_GDT
gdt_ptr:    dw gdt_len-1
            dd 0

selector_ring0_code equ LABEL_DESC_RING0_CODE-LABEL_GDT
selector_ring3_code equ LABEL_DESC_RING3_CODE-LABEL_GDT+SA_RPL3
selector_ring0_stack equ LABEL_DESC_RING0_STACK-LABEL_GDT
selector_ring3_stack equ LABEL_DESC_RING3_STACK-LABEL_GDT+SA_RPL3
selector_call_gate_code equ LABEL_DESC_CALL_GATE_CODE-LABEL_GDT
selector_video equ LABEL_DESC_VIDEO-LABEL_GDT
selector_tss equ LABEL_DESC_TSS-LABEL_GDT
selector_call_gate equ LABEL_CALL_GATE-LABEL_GDT+SA_RPL3        ; rpl为3
; SECTION gdt

[SECTION .ring0_stack]
LABEL_RING0_STACK:
    times 512 db 0
bottom_of_ring0_stack equ $-LABEL_RING0_STACK-1

[SECTION .ring3_stack]
LABEL_RING3_STACK:
    times 512 db 0
bottom_of_ring3_stack equ $-LABEL_RING3_STACK-1

[SECTION .idt]
ALIGN 32
[BITS 32]
LABEL_IDT:
%rep 0x20
    GATE selector_ring0_code, default_handler, 0, DA_386INTGATE
%endrep
.0x21:  ; 时钟中断
    GATE selector_ring0_code, clock_handler, 0, DA_386INTGATE
%rep (0x81-0x22)
    GATE selector_ring0_code, default_handler, 0, DA_386INTGATE
%endrep
.0x81:  ; 0x80中断
    ; 此中断门特权级为3的代码需要使用
    GATE selector_ring0_code, int_0x80_handler, 0, DA_386INTGATE|DA_DPL3
%rep (0xff-0x81)
    GATE selector_ring0_code, default_handler, 0, DA_386INTGATE
%endrep

idt_len equ $-LABEL_IDT
idt_ptr dw idt_len-1
        dd 0
; SECTION idt

[SECTION .tss]
ALIGN 32
[BITS 32]
LABEL_TSS:
    dd 0
    dd bottom_of_ring0_stack        ; 特权级0栈
    dd selector_ring0_stack
    dd 0                            ; 特权级1栈
    dd 0
    dd 0                            ; 特权级2栈
    dd 0
    dd 0                            ; cr3
    dd 0                            ; eip
    dd 0                            ; eflags
    dd 0                            ; eax
    dd 0                            ; ecx
    dd 0                            ; edx
    dd 0                            ; ebx
    dd 0                            ; esp
    dd 0                            ; ebp
    dd 0                            ; esi
    dd 0                            ; edi
    dd 0                            ; es
    dd 0                            ; cs
    dd 0                            ; ss
    dd 0                            ; ds
    dd 0                            ; fs
    dd 0                            ; gs
    dd 0                            ; ldt
    dw 0                            ; 调试陷阱标志
    dw $-LABEL_TSS+2                ; i/o位图基址
    dw 0xff                         ; i/o位图标志
    
seg_tss_len equ $-LABEL_TSS

[SECTION .rm_code]
[BITS 16]
LABEL_BEGIN:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ax, 0x4000                       ; 实模式把栈段设置成这个值安全
    mov ss, ax
    mov sp, 0x1000
    
    ; 在实模式下初始化所有描述符
    INIT_DESCRIPTOR LABEL_DESC_RING0_CODE, LABEL_SEG_RING0_CODE
    INIT_DESCRIPTOR LABEL_DESC_RING3_CODE, LABEL_SEG_RING3_CODE
    INIT_DESCRIPTOR LABEL_DESC_RING0_STACK, LABEL_RING0_STACK
    INIT_DESCRIPTOR LABEL_DESC_RING3_STACK, LABEL_RING3_STACK
    INIT_DESCRIPTOR LABEL_DESC_TSS, LABEL_TSS
    INIT_DESCRIPTOR LABEL_DESC_CALL_GATE_CODE, LABEL_CALL_GATE_CODE
    
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
    
    ; 进入保护模式
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    
    jmp word selector_ring0_code:0
; 实模式代码到此结束
    
%macro PRINT_CHAR 2
    mov al, (%2)
    mov [gs:(%1)], ax
%endmacro
    
[SECTION .call_gate_code]
[BITS 32]
LABEL_CALL_GATE_CODE:
    ; 尝试打印一些东西
    ; 打印call gate，大小写交替进行
    mov ax, selector_video
    mov gs, ax
    
    mov ah, 0x0c
    mov al, [gs:((80*12+35)*2)]
    cmp al, 'c'
    jz .CALL_GATE
    
.call_gate:
    PRINT_CHAR ((80*12+35)*2), 'c'
    PRINT_CHAR ((80*12+36)*2), 'a'
    PRINT_CHAR ((80*12+37)*2), 'l'
    PRINT_CHAR ((80*12+38)*2), 'l'
    PRINT_CHAR ((80*12+39)*2), ' '
    PRINT_CHAR ((80*12+40)*2), 'g'
    PRINT_CHAR ((80*12+41)*2), 'a'
    PRINT_CHAR ((80*12+42)*2), 't'
    PRINT_CHAR ((80*12+43)*2), 'e'
    jmp .done
.CALL_GATE:
    PRINT_CHAR ((80*12+35)*2), 'C'
    PRINT_CHAR ((80*12+36)*2), 'A'
    PRINT_CHAR ((80*12+37)*2), 'L'
    PRINT_CHAR ((80*12+38)*2), 'L'
    PRINT_CHAR ((80*12+39)*2), ' '
    PRINT_CHAR ((80*12+40)*2), 'G'
    PRINT_CHAR ((80*12+41)*2), 'A'
    PRINT_CHAR ((80*12+42)*2), 'T'
    PRINT_CHAR ((80*12+43)*2), 'E'
.done:
    retf
    
seg_call_gate_code_len equ $-LABEL_CALL_GATE_CODE
    
[SECTION .ring0_code]
[BITS 32]
LABEL_SEG_RING0_CODE:
    mov ax, selector_video
    mov gs, ax
    mov ax, selector_ring0_stack
    mov ss, ax
    mov esp, bottom_of_ring0_stack
    
    ; 初始化8259芯片
    call init_8259a
    
    ; 载入任务的tss
    mov ax, selector_tss
    ltr ax
    
    sti                     ; 开启中断
    
    ; 模拟从调用门返回将特权级转换到特权级3
    push selector_ring3_stack
    push bottom_of_ring3_stack
    push selector_ring3_code
    push 0
    retf
    
; 初始化8259芯片    
init_8259a:
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
    out 0x21, al            ; 主8259，OCW1
    call io_delay
    
    mov al, 0xfe            ; 仅仅开启从块上的时钟中断
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

_default_handler:
default_handler equ _default_handler-$$
    mov ah, 0x0c
    mov al, '!'
    mov [gs:((80*0+75)*2)], ax
    iretd
    
_int_0x80_handler:
int_0x80_handler equ _int_0x80_handler-$$
    mov ah, 0x0c
    mov al, '8'
    mov [gs:((80*11+39)*2)], ax
    mov al, '0'
    mov [gs:((80*11+40)*2)], ax
    iretd
    
_clock_handler:
clock_handler equ _clock_handler-$$
    ; 这里的代码必须足够的快，因为时钟中断十分频繁，
    ; 如果这里有延迟，特权级为3的代码根本没有机会执行
    mov ah, 0x0c
    mov al, [gs:((80*0+70)*2)]
    cmp al, 'A'
    jz .BA
    
.AB:
    mov al, 'A'
    mov [gs:((80*0+70)*2)], ax
    mov al, 'B'
    mov [gs:((80*0+71)*2)], ax
    jmp .done
.BA:
    mov al, 'B'
    mov [gs:((80*0+70)*2)], ax
    mov al, 'A'
    mov [gs:((80*0+71)*2)], ax

.done:
    mov al, 0x20
    out 0x20, al                        ; 发送eoi
    iretd
    
seg_ring0_code_len equ $-LABEL_SEG_RING0_CODE
; 特权级别为0的代码结束

[SECTION .ring3_code]
ALIGN 32
[BITS 32]
LABEL_SEG_RING3_CODE:
    
.loop:
    mov ecx, 0xfffffff                  ; 采用死循环延时
    loop $
    
    call selector_call_gate:0
    int 0x80
    jmp .loop
    
seg_ring3_code_len equ $-LABEL_SEG_RING3_CODE
