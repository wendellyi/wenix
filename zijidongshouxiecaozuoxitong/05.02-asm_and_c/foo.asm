extern choose                   ; int choose(int a, int b);

[section .data]
a dd 3
b dd 4

[section .text]
global _start
global print

_start:
;; 从右向左如栈
    push dword [b]
    push dword [a]
    call choose
    add esp, 8

    mov ebx, 0
    mov eax, 1
    int 0x80

print:
    mov edx, [esp+8]
    mov ecx, [esp+4]
    mov ebx, 1
    mov eax, 4
    int 0x80
    ret