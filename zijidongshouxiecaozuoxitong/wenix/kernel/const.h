#ifndef _WENIX_CONST_H_
#define _WENIX_CONST_H_


#define GDT_SIZE 128            /* gdt表项的个数 */
#define IDT_SIZE 256            /* idt表项的个数 */

/* 8259控制掩码 */
#define INT_M_CTL               0x20 /* 控制的i/o端口 */
#define INT_M_CTL_MASK          0x21 /* 开启或者禁止中断的掩码 */
#define INT_S_CTL               0xa0
#define INT_S_CTL_MASK          0xa1

/* 中断向量 */
#define INT_VECTOR_IRQ0         0x20
#define INT_VECTOR_IRQ8         0x28

#endif  /* _WENIX_CONST_H_ */
