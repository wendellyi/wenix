%include "../../pm.inc"

jmp LABEL_BEGIN                 ; 直接跳转到开始处

[SECTION .gdt]
LABEL_GDT:                  DESCRIPTOR 0, 0, 0
LABEL_DESC_RING0_CODE:      DESCRIPTOR 0, seg_ring0_code_len-1, DA_C|DA_32
LABEL_DESC_RING3_CODE:      DESCRIPTOR 0, seg_ring3_code_len-1, DA_C|DA_32|DA_DPL3
LABEL_DESC_RING0_STACK:     DESCRIPTOR 0, bottom_of_ring0_stack, DA_DRWA|DA_32
LABEL_DESC_RING3_STACK:     DESCRIPTOR 0, bottom_of_ring3_stack, DA_DRWA|DA_32|DA_DPL3
LABEL_DESC_CODE_DST:    DESCRIPTOR 0, seg_code_dst_len-1, DA_C|DA_32
LABEL_DESC_VIDEO:       DESCRIPTOR 0xb8000, 0xffff, DA_DRW+DA_DPL3
LABEL_DESC_TSS:         DESCRIPTOR 0, seg_tss_len-1, DA_386TSS
LABEL_CALL_GATE:        GATE selector_code_dst, 0, 0, DA_386CALLGATE+DA_DPL3


gdt_len equ $-LABEL_GDT
gdt_ptr:    dw gdt_len-1
            dd 0

selector_ring0_code equ LABEL_DESC_RING0_CODE-LABEL_GDT
selector_ring3_code equ LABEL_DESC_RING3_CODE-LABEL_GDT|SA_RPL3
selector_ring0_stack equ LABEL_DESC_RING0_STACK-LABEL_GDT
selector_ring3_stack equ LABEL_DESC_RING3_STACK-LABEL_GDT+SA_RPL3
selector_video equ LABEL_DESC_VIDEO-LABEL_GDT
selector_tss equ LABEL_DESC_TSS-LABEL_GDT
selector_call_gate equ LABEL_CALL_GATE-LABEL_GDT+SA_RPL3
selector_code_dst equ LABEL_DESC_CODE_DST-LABEL_GDT

[SECTION .data]
ALIGN 32
[BITS 32]
LABEL_DATA:
sp_in_real_mode dw 0
pm_msg: db "in protect mode now ...", 0
pm_msg_offset equ pm_msg-$$
rm_msg: db "in real mode again ..."
rm_msg_len equ $-rm_msg
test_string: db "ABCDEFGHIGKLMNOPQRSTUVWXYZ", 0
test_string_offset equ test_string-$$
data_len equ $-LABEL_DATA

[SECTION .ring0_stack]
ALIGN 32
[BITS 32]
LABEL_RING0_STACK:
    times 512 db 0

bottom_of_ring0_stack equ $-LABEL_RING0_STACK-1

[SECTION .ring3_stack]
ALIGN 32
[BITS 32]
LABEL_RING3_STACK:
    times 512 db 0
bottom_of_ring3_stack equ $-LABEL_RING3_STACK-1

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
    dd 0                    ; eip
    dd 0                    ; eflags
    dd 0                    ; eax
    dd 0                    ; ecx
    dd 0                    ; edx
    dd 0                    ; ebx
    dd 0                    ; esp
    dd 0                    ; ebp
    dd 0                    ; esi
    dd 0                    ; edi
    dd 0                    ; es
    dd 0                    ; cs
    dd 0                    ; ss
    dd 0                    ; ds
    dd 0                    ; fs
    dd 0                    ; gs
    dd 0                    ; ldt
    dw 0                    ; 调试陷阱标志
    dw $-LABEL_TSS+2        ; i/o位图基址
    dw 0xff                 ; i/o位图标志
    
seg_tss_len equ $-LABEL_TSS

[SECTION .s16]
[BITS 16]
LABEL_BEGIN:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x0100
    
    ; 在实模式下初始化所有描述符
    INIT_DESCRIPTOR LABEL_DESC_RING0_CODE, LABEL_SEG_RING0_CODE
    INIT_DESCRIPTOR LABEL_DESC_RING3_CODE, LABEL_SEG_RING3_CODE
    INIT_DESCRIPTOR LABEL_DESC_RING0_STACK, LABEL_RING0_STACK
    INIT_DESCRIPTOR LABEL_DESC_RING3_STACK, LABEL_RING3_STACK
    
    
    
    INIT_DESCRIPTOR LABEL_DESC_TSS, LABEL_TSS
    INIT_DESCRIPTOR LABEL_DESC_CODE_DST, LABEL_SEG_CODE_DST
    
    ; 进入保护模式
    xor eax, eax
    mov ax, ds
    shl eax, 4
    add eax, LABEL_GDT
    mov dword [gdt_ptr+2], eax    
    lgdt [gdt_ptr]
    cli
    in al, 0x92
    or al, 0x02
    out 0x92, al
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp word selector_ring0_code:0
    
[SECTION .seg_ring0_code]
[BITS 32]
LABEL_SEG_RING0_CODE:
    mov ax, selector_video
    mov gs, ax
    mov ax, selector_ring0_stack
    mov ss, ax
    mov esp, bottom_of_ring0_stack
    
    ; 加载tss
    mov ax, selector_tss
    ltr ax
    
    push selector_ring3_stack
    push bottom_of_ring3_stack
    push selector_ring3_code
    push 0
    retf
    
seg_ring0_code_len equ $-LABEL_SEG_RING0_CODE

[SECTION .seg_ring3_code]
ALIGN 32
[BITS 32]
LABEL_SEG_RING3_CODE:
    mov ax, selector_video
    mov gs, ax
    mov edi, (80*14+0)*2
    mov ah, 0x0c
    mov al, '3'
    mov [gs:edi], ax
    
    ; 现在是特权级3，需要调用特权级0的过程
    ; 所以需要tss和调用门参与
    call selector_call_gate:0
    
seg_ring3_code_len equ $-LABEL_SEG_RING3_CODE

[SECTION .sdst]
[BITS 32]
LABEL_SEG_CODE_DST:
    mov ax, selector_video
    mov gs, ax
    
    mov edi, (80*12+0)*2
    mov ah, 0x0c
    mov al, 'C'
    mov [gs:edi], ax
    
    add edi, 2
    mov al, 'G'
    mov [gs:edi], ax
    
    jmp $
    
seg_code_dst_len equ $-LABEL_SEG_CODE_DST