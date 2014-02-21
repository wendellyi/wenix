[SECTION .data]
string db 'Hello World', 0x0a
strlen equ $-string

[SECTION .text]

global _start

_start:
    mov edx, strlen
    mov ecx, string
    mov ebx, 1
    mov eax, 4
    int 0x80
    mov ebx, 0
    mov eax, 1
    int 0x80