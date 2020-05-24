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
setup: 
    call generate_code

    mov di, chance_count
    xor ax, ax
    stosw                   ;set current chance_count to 0
.screen:
    xor di, di
    mov cx, 1000            ;40x25 chars
    rep stosw               ;clear screen

    mov si, title_message
    mov di, title_message_position
    mov cx, title_message_length
    call print_string

    mov si, chances_message
    mov di, chances_message_position
    mov cx, chances_message_length
    call print_string
.code_pad:
    xor cx, cx
.loop1:
    xor bx, bx
.loop2:
    mov di, code_pad
    mov ax, screen_width
    mul cx
    add di, ax
    mov dx, bx
    shl dx, 1
    add di, dx                 ;set di to point to code_pad[screen_width*cx + dx]

    cmp bx, code_pad_width
    je .draw_border
    cmp bx, 0
    je .draw_border
    cmp cx, code_pad_width
    je .draw_border
    jcxz .draw_border
    jmp .skip_draw_border
.draw_border:
    mov ax, border
    stosw
.skip_draw_border:
    inc bx
    cmp bx, code_pad_width
    jle .loop2

    inc cx
    cmp cx, code_pad_width
    jle .loop1

.input:
    mov di, code_input
    mov cx, code_length
    mov ax, underscore
    rep stosw
.chances:
    mov si, chance_count
    lodsw
    mov di, chance_count_position+4
    mov bx, chances_char
    xchg bx, ax
    stosw
    sub di, 6
    sub ax, bx
    stosw
    cmp bx, chances
    je lose


get_code:
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

evaluate_code:
    mov di, code_entries
    mov si, chance_count
    lodsw
    mov dx, screen_width
    mul dx
    add di, ax
    push di
    xor cx, cx
.loop:
    push cx
    call evaluate_char
    pop cx
    mov ax, bx              ;bx has char from evaluate_char
    mov dx, cx
    stosw 

    inc cx
    cmp cx, code_length
    jne .loop

    mov si, code
    mov di, code_input
    mov cx, code_length+1
    repe cmpsw
    jcxz win
    mov si, chance_count
    lodsw
    inc ax
    mov di, chance_count
    stosw
    jmp setup.input

win:
    mov si, win_message
    mov di, win_message_position
    mov cx, win_message_length
    call print_string
    jmp reset

lose:
    mov di, chance_count_position
    mov ax, zero
    stosw
    mov si, lose_message
    mov di, lose_message_position
    mov cx, lose_message_length
    call print_string

reset:
    xor ah, ah
    int 0x16
    jmp setup


evaluate_char:
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


print_string:
    xor ax, ax
    mov ds, ax
    mov dx, cx
    xor cx, cx
.loop:
    mov ah, white
    mov al, [si]
    stosw
    inc cx
    inc si
    cmp cx, dx
    jne .loop

    mov ax, text_buffer
    mov ds, ax
    mov es, ax
    ret


generate_code:
    xor ax, ax
    int 0x1A
    push dx
    xor cx, cx
    mov di, code
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
    inc cx
    cmp cx, code_length
    jne .generate_digit

    pop ax
    ret


text_buffer equ 0xB800
screen_width equ 80
code equ 0x7D0
code_length equ 6
chances equ 6
chance_count equ 0x800

code_input equ 0x29A
code_entries equ 0x2B6

code_pad equ 0x1F6
code_pad_width equ 9
code_pad_height equ 4

title_message db "CODEBREAKER"
title_message_length equ $ - title_message
title_message_position equ 0x1E
chances_message db "CHANCES: ( / )"
chances_message_length equ $ - chances_message
chances_message_position equ 0x1C0
chance_count_position equ chances_message_position + 20
win_message db "YOU ARE IN!"
win_message_length equ $ - win_message
win_message_position equ 0x65E
lose_message db "YOU GOT CAUGHT!"
lose_message_length equ $ - lose_message
lose_message_position equ 0x65A

white equ 0xF
border equ 0xFDB
underscore equ 0xF5F
zero equ 0xF30
chances_char equ zero + chances

times 510 - ($ - $$) db 0
dw 0xAA55