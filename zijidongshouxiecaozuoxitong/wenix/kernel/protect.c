#include "type.h"
#include "const.h"
#include "protect.h"
#include "global.h"
#include "proto.h"              /* 真不知道这个名称代表何意 */



static void init_idt_desc(u8 vector, u8 type, void (*handler) (void), u8 privilege)
{
    struct GATE* gate = &idt[vector];
    u32 base = (u32)handler;
    gate->offset_low = base & 0xffff;
    gate->selector = SELECTOR_KERNEL_CS;
    gate->param_count = 0;
    gate->attribute = type | (privilege << 5);
    gate->offset_high = (base >> 16) & 0xffff;
}

void zero_divided(void);

void init_interrupt(void)
{
    init_8259a();

    /* 下面初始化中断向量各个表项 */
    init_idt_desc(INT_VECTOR_ZERO_DIVIDE, DA_386INTGATE, zero_divided, DPL_KERNEL);
    init_idt_desc(INT_VECTOR_DEBUG, DA_386INTGATE, single_step, DPL_KERNEL);
    init_idt_desc(INT_VECTOR_NMI, DA_386INTGATE, nmi, DPL_KERNEL);
    init_idt_desc(INT_VECTOR_BREAKPOINT, DA_386INTGATE, breakpoint, DPL_USER);
    init_idt_desc(INT_VECTOR_OVERFLOW, DA_386INTGATE, overflow, DPL_USER);
    init_idt_desc(INT_VECTOR_BOUNDS, DA_386INTGATE, bounds_check, DPL_KERNEL);
    init_idt_desc(INT_VECTOR_INVALID_OP, DA_386INTGATE, invalid_op, DPL_KERNEL);
    
    /* 数学协处理器不可用 */
    init_idt_desc(INT_VECTOR_DEV_NOT_AVL, DA_386INTGATE, dev_not_avl, DPL_KERNEL);
    init_idt_desc(INT_VECTOR_DOUBLE_FAULT, DA_386INTGATE, double_fault, DPL_KERNEL);

    /* 数学协处理器不可用 */
    init_idt_desc(INT_VECTOR_COPROC_SEG_FAULT, DA_386INTGATE, coproc_seg_fault, DPL_KERNEL);
    init_idt_desc(INT_VECTOR_INVALID_TSS, DA_386INTGATE, invalid_tss, DPL_KERNEL);
    init_idt_desc(INT_VECTOR_SEG_NOT_PRESENT, DA_386INTGATE, segment_not_present, DPL_KERNEL);
    init_idt_desc(INT_VECTOR_SEG_STACK_FAULT, DA_386INTGATE, stack_exception, DPL_KERNEL);
    init_idt_desc(INT_VECTOR_GP, DA_386INTGATE, general_protection, DPL_KERNEL);
    init_idt_desc(INT_VECTOR_PAGE_FAULT, DA_386INTGATE, page_fault, DPL_KERNEL);
    init_idt_desc(INT_VECTOR_COPROC_ERROR, DA_386INTGATE, coproc_error, DPL_KERNEL);
}

void exception_handler(
    int irq, int err_code, int eip, int cs, int eflags)
{
    int i;
    int text_color = 0x74;      /* 灰底红字 */

	char * err_msg[] ={
        "#DE Divide Error",
        "#DB RESERVED",
        "--  NMI Interrupt",
        "#BP Breakpoint",
        "#OF Overflow",
        "#BR BOUND Range Exceeded",
        "#UD Invalid Opcode (Undefined Opcode)",
        "#NM Device Not Available (No Math Coprocessor)",
        "#DF Double Fault",
        "    Coprocessor Segment Overrun (reserved)",
        "#TS Invalid TSS",
        "#NP Segment Not Present",
        "#SS Stack-Segment Fault",
        "#GP General Protection",
        "#PF Page Fault",
        "--  (Intel reserved. Do not use.)",
        "#MF x87 FPU Floating-Point Error (Math Fault)",
        "#AC Alignment Check",
        "#MC Machine Check",
        "#XF SIMD Floating-Point Exception"
    };

	/* 通过打印空格的方式清空屏幕的前五行，并把 disp_pos 清零 */
	disp_pos = 0;
	for(i=0;i<80*5;i++){
		disp_str(" ");
	}
	disp_pos = 0;

	disp_color_str("Exception! --> ", text_color);
	disp_color_str(err_msg[vec_no], text_color);
	disp_color_str("\n\n", text_color);
	disp_color_str("EFLAGS:", text_color);
	disp_int(eflags);
	disp_color_str("CS:", text_color);
	disp_int(cs);
	disp_color_str("EIP:", text_color);
	disp_int(eip);

	if(err_code != 0xFFFFFFFF){
		disp_color_str("Error code:", text_color);
		disp_int(err_code);
	}    char* err_msg[] = {
        "#DB RESERVED",
        "-- NMI Interrupt",
        "#OF Overflow",
    };
}
