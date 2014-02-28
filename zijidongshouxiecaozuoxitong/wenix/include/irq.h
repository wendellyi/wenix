#ifndef _IRQ_H_
#define _IRQ_H_

/* 8259控制掩码 */
#define INT_M_CTL               0x20 /* 控制的i/o端口 */
#define INT_M_CTL_MASK          0x21 /* 开启或者禁止中断的掩码 */
#define INT_S_CTL               0xa0
#define INT_S_CTL_MASK          0xa1

/* 中断向量 */
#define INT_VECTOR_IRQ0         0x20
#define INT_VECTOR_IRQ8         0x28

/* 中断向量 */
#define INT_VECTOR_ZERO_DIVIDE                  0x00
#define INT_VECTOR_SINGLE_STEP                  0x01
#define INT_VECTOR_NMI                          0x02
#define INT_VECTOR_BREAKPOINT                   0x03
#define INT_VECTOR_OVERFLOW                     0x04
#define INT_VECTOR_BOUNDS                       0x05
#define INT_VECTOR_INVALID_OP                   0x06
#define INT_VECTOR_DEV_NOT_AVL                  0x07
#define INT_VECTOR_DOUBLE_FAULT                 0x08
#define INT_VECTOR_COPROC_SEG_FAULT             0x09
#define INT_VECTOR_INVALID_TSS                  0x0a
#define INT_VECTOR_SEG_NOT_PRESENT              0x0b
#define INT_VECTOR_SEG_STACK_FAULT              0x0c
#define INT_VECTOR_GP                           0x0d
#define INT_VECTOR_PAGE_FAULT                   0x0e
#define INT_VECTOR_COPROC_ERROR                 0x0f

void zero_divided(void);
void single_step(void);
void nmi(void);
void breakpoint(void);
void overflow(void);
void bounds_check(void);
void invalid_op(void);
void dev_not_avl(void);
void double_fault(void);
void coproc_seg_fault(void);
void invalid_tss(void);
void segment_not_present(void);
void stack_exception(void);
void general_protection(void);
void page_fault(void);
void coproc_error(void);

void hwint00(void);
void hwint01(void);
void hwint02(void);
void hwint03(void);
void hwint04(void);
void hwint05(void);
void hwint06(void);
void hwint07(void);
void hwint08(void);
void hwint09(void);
void hwint10(void);
void hwint11(void);
void hwint12(void);
void hwint13(void);
void hwint14(void);
void hwint15(void);

#endif  /* _IRQ_H_ */
