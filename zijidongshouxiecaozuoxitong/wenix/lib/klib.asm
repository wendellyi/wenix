[section .data]
display_position dd 0

[section .text]

global display_string

;; 功能：显示字符串
;; void display_string(char * string);
display_string:
    push ebp
    mov ebp, esp

    mov esi, [ebp + 8]          ; 第一个参数，也就是string
    mov edi, [display_position]
    mov ah, 0x0f
.1:
    lodsb
    test al, al                 ; 判断是否遇到空字符
    jz .2
    cmp al, 0x0a                ; 是回车吗
    jnz .3
    push eax
    mov eax, edi
    mov bl, 160
    div bl
    and eax, 0xff
    inc eax
    mov bl, 160
    mul bl
    mov edi, eax
    pop eax
    jmp .1
.3:
    mov [gs:edi], ax
    add edi, 2
    jmp .1

.2:
    mov [display_position], edi
    mov esp, ebp                ;清理栈
    pop ebp
    ret

