SELECTOR_KERNEL_CS equ 8

[section .text]
global zero_divided
global single_step
global nmi
global breakpoint
global overflow
global bounds_check
global invalid_op
global dev_not_avl
global double_fault
global coproc_seg_fault
global invalid_tss
global segment_not_present
global stack_exception
global general_protection
global page_fault
global coproc_error
global hwint00
global hwint01
global hwint02
global hwint03
global hwint04
global hwint05
global hwint06
global hwint07
global hwint08
global hwint09
global hwint10
global hwint11
global hwint12
global hwint13
global hwint14
global hwint15

%macro hwint_master 1
    push (%1)
    call spurious_irq
    add esp, 4
    hlt
%endmacro

align 16                        ; 时钟中断
hwint00:
    hwint_master 0

align 16                        ; 键盘中断
hwint01:
    hwint_master 0

align 16                        ; 
hwint02:
    hwint_master 0

align 16                        ; 从串口
hwint03:
    hwint_master 0

align 16                        ; 主串口
hwint04:
    hwint_master 0

align 16                        ;
hwint05:
    hwint_master 0

align 16                        ; 软驱
hwint06:
    hwint_master 0

align 16                        ; 打印机
hwint07:
    hwint_master 0

%macro hwint_slave 1
    push (%1)
    call spurious_irq
    add esp, 4
    hlt
%endmacro

align 16
hwint08                         ; 实时时钟
    hwint_slave 8

align 16                        ;
hwint09
    hwint_slave 9

align 16                        ;
hwint10
    hwint_slave 10

align 16                        ;
hwint11
    hwint_slave 11

align 16                        ;
hwint12
    hwint_slave 12

align 16
hwint13
    hwint_slave 13              ; fpu异常

align 16
hwint14
    hwint_slave 14

align 16                        ;
hwint15
    hwint_slave 15

;; 中断与异常，压入0xffffffff表示没有错误码
zero_divided:
    push 0xffffffff             ; 错误码
    push 0                      ; irq号为0
    jmp exception

single_step:
    push 0xffffffff
    push 1
    jmp exception

nmi:
    push 0xffffffff
    push 2
    jmp exception

breakpoint:
    push 0xffffffff
    push 3
    jmp exception

overflow:
    push 0xffffffff
    push 4
    jmp exception

bounds_check:
    push 0xffffffff
    push 5
    jmp exception

invalid_op:
    push 0xffffffff
    push 6
    jmp exception

dev_not_avl:
    push 0xffffffff
    push 7
    jmp exception

double_fault:
    push 8
    jmp exception

coproc_seg_fault:
    push 0xffffffff
    push 9
    jmp exception

invalid_tss:
    push 10
    jmp exception

segment_not_present
    push 11
    jmp exception

stack_exception:
    push 12
    jmp exception

general_protection:
    push 13
    jmp exception

page_fault:
    push 14
    jmp exception

coproc_error:
    push 0xffffffff
    push 16
    jmp exception

exception:
    call exception_handler
    add esp, 8
    hlt