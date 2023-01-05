BITS 16                     ;16-bit real mode
[org 0x7C00]                ;set addresses realtive to where the code got loaded

start:
    mov bp, 0x9000          ;stack at 0x9000
    mov sp, bp

    mov ax, 0x1             ;set message mode 40x25 chars
    int 0x10

    cld                     ;clear flags, so string operations add di

    mov ax, text_buffer
    mov ds, ax              ;ds and es are segment registers
    mov es, ax              ;they are shifted by half a byte
                            ;and di or si are added respectively
                            ;for string operations
Setup:
    xor ax, ax
    xor di, di
    mov cx, 1000            ;40x25 chars
    rep stosw               ;clear screen

    mov si, title_message
    mov di, title_message_position
    call PrintString

    mov si, chances_message
    mov di, chances_message_position
    call PrintString

GenerateCode:
    int 0x1A
    push dx
    mov di, code
    mov cx, code_length

.generate_digit:
    pop ax

    mov bx, 25173
    mul bx
    add ax, 13849
    push ax

    mov bx, 10
    xor dx, dx
    div bx
    mov ax, zero
    add ax, dx

    push cx
    push di
    mov cx, code_length+1
    mov di, code
    repne scasw
    pop di
    jcxz .save_digit
    pop cx
    jmp .generate_digit
.save_digit:
    pop cx
    stosw
    loop .generate_digit

    pop ax

SetupCodePad:
    xor bx, bx
.loop:
    mov di, code_pad
    mov ax, screen_width
    mul bx
    add di, ax
    mov dx, code_pad_width
    mov cx, dx
    mov ax, border
    rep stosw

    inc bx
    cmp bx, dx
    jb .loop

.input:
    mov di, code_input
    mov cx, code_length
    mov ax, underscore
    rep stosw


GetCode:
    mov di, code_input
    xor cx, cx
.loop:
    xor ah, ah
    int 0x16                ;get key stroke as char in al

    cmp al, 0x8             ;backspace
    je .backspace
    cmp al, 0xD             ;enter
    je .enter
    cmp cx, code_length     ;when code has been entered
    je .loop                ;dont allow more digits
    cmp al, '0'             ;when key stroke is not
    jl .loop                ;a digit get new keystroke
    cmp al, '9'
    jg .loop

    mov ah, white
    stosw

    inc cx
    jmp .loop
.backspace:
    jcxz .loop              ;dont allow backspace at the first postiion
    dec cx
    sub di, 2
    mov ax, underscore
    stosw
    sub di, 2
    jmp .loop
.enter:
    cmp cx, code_length     ;when code contains all necessary digits
    jne .loop               ;go on to evaluate the code

EvaluateCode:
    mov di, code_entries
    mov ax, [max_chances]
    mov cx, [chances]
    sub ax, cx
    mov dx, screen_width
    mul dx
    add di, ax
    push di
    xor cx, cx
.loop:
    push cx
    call EvaluateChar
    pop cx
    mov ax, bx              ;bx has char from EvaluateChar
    mov dx, cx
    stosw

    inc cx
    cmp cx, code_length
    jne .loop

    mov si, code
    mov di, code_input
    mov cx, code_length+1
    repe cmpsw
    jcxz Win
    mov cx, [chances]
    dec cx
    mov [chances], cx
    sub cx, zero
    jcxz Loss
    jmp SetupCodePad.input

Win:
    mov si, win_message
    mov di, win_message_position
    call PrintString
    jmp WaitForReset

Loss:
    mov si, win_message
    mov di, lose_message_position
    call PrintString
    mov si, lose_message
    mov di, lose_message_position+8
    call PrintString

WaitForReset:
    xor ah, ah
    int 0x16
    jmp Setup


EvaluateChar:
    mov si, code_input
    shl cx, 1
    add si, cx
    lodsw
    mov bx, ax
    push cx
    xor cx, cx
.iterate_code:
    mov si, code
    mov dx, cx
    shl dx, 1
    add si, dx
    lodsw

    cmp al, bl              ;compare al with code[cx]
    je .found
    inc cx
    cmp cx, code_length
    je .red
    jmp .iterate_code
.found:
    pop dx
    shl cx, 1
    cmp cx, dx              ;compare if position matches
    je .green
.yellow:
    mov bh, 0xE
    ret
.green:
    mov bh, 0xA
    ret
.red:
    pop dx
    mov bh, 0xC
    ret

; si: source
; di: destination
PrintString:
    push ax
    xor ax, ax
    mov ds, ax
    mov ah, white

.print_char:
    lodsb
    or al, al
    jz .return
    stosw
    jmp .print_char

.return:
    mov ax, text_buffer
    mov ds, ax
    pop ax
    ret


text_buffer equ 0xB800
screen_width equ 80
code equ 0x7D0
code_length equ 7

code_input equ 0x29A
code_entries equ 0x2B6

code_pad equ 0x1F6
code_pad_width equ code_length+4

title_message db "CODEBREAKER", 0
title_message_position equ 0x1E

chances_message db "CHANCES: (4/4)", 0
chances_message_position equ 0x1C0
chances equ chances_message_position + 20
max_chances equ chances_message_position + 24

win_message db "YOU ARE IN!", 0
win_message_position equ 0x65E

lose_message db "GOT CAUGHT!", 0
lose_message_position equ 0x65A

white equ 0xF
border equ 0x7DB
underscore equ 0xF5F
zero equ 0xF30

end_of_asm equ 440
padding times end_of_asm - ($ - $$) db 0xF4
partition_table times 510 - end_of_asm db 0
boot_signature dw 0xAA55