#include "type.h"
#include "const.h"
#include "protect.h"
#include "global.h"
#include "proto.h"



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
    init_idt_desc(INT_VECTOR_
    init_idt_desc(
    init_idt_desc(
    init_idt_desc(
    init_idt_desc(
    init_idt_desc(
    init_idt_desc(
    init_idt_desc(
    init_idt_desc(
    init_idt_desc(
    init_idt_desc(
    init_idt_desc(
    init_idt_desc(
    init_idt_desc(
    init_idt_desc(
    init_idt_desc(
    init_idt_desc(
    init_idt_desc(
    init_idt_desc(
    init_idt_desc(
    init_idt_desc(
    init_idt_desc(
    init_idt_desc(
    init_idt_desc(
    init_idt_desc(
    init_idt_desc(
    init_idt_desc(
    init_idt_desc(

}
