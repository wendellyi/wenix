#ifndef _WENIX_PROTECT_H
#define _WENIX_PROTECT_H

/* 描述符数据结构 */
struct DESCRIPTOR
{
    u16 limit_low;              /* limit */
    u16 base_low;               /* base */
    u8 base_mid;                /* base */
    u8 attr1;                   /* p(1) dpl(2) dt(1) type(4) */
    u8 limit_hight_attr2;       /* g(1) d(1) 0(1) avl(1) limit_high(4) */
    u8 base_high;               /* base */
};

/* 门描述符 */
struct GATE
{
    u16 offset_low;
    u16 selector;
    u8 param_count;             /* 该字段只在门描述符中有效
                                 * 表示复制的参数个数
                                 */
    u8 attribute;
    u16 offset_high;
};

#endif  /* _WENIX_PROTECT_H */
