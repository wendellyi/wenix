[section .text]

global _start                   ; 导出_start

_start:
    mov ah, 0x0f                ; 黑底白字
    mov al, 'K'
    mov [gs:((80*1+39)*2)], ax
    jmp $