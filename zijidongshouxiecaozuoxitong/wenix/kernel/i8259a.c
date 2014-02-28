#include "irq.h"

void init_8259a(void)
{
    /* master 8259 icw1 */
    out_byte(INT_M_CTL, 0x11);

    /* slave 8259 icw1 */
    out_byte(INT_S_CTL, 0x11);

    /* master 8259 icw2 主8259的中断起始地址为0x20 */
    out_byte(INT_M_CTL_MASK, INT_VECTOR_IRQ0);

    /* slave 8259 icw2 从8259的中断起始地址为0x28 */
    out_byte(INT_S_CTL_MASK, INT_VECTOR_IRQ8);

    /* master 8259 icw3 irq2对应从8259 */
    out_byte(INT_M_CTL_MASK, 0x04);

    /* slave 8259 icw3 对应主8259irq2 */
    out_byte(INT_S_CTL_MASK, 0x02);

    /* master 8259 icw4 */
    out_byte(INT_M_CTL_MASK, 0x01);

    /* slave 8259 icw4 */
    out_byte(INT_S_CTL_MASK, 0x01);

    /* 中断全部关闭 */
    /* master 8259 ocw1 */
    out_byte(INT_M_CTL_MASK, 0xff);

    /* slave 8259 ocw1 */
    out_byte(INT_S_CTL_MASK, 0xff);
}

void spurious_irq(int irq)
{
    display_string("spurious_irq: ");
    display_int(irq);
    display_string("\n");
}
