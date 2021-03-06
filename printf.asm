section .text
;global _start 
_start:     

            mov rdi, 42
            push rdi
            mov rdi, 42
            push rdi
            mov rdi, 42
            push rdi
            mov rdi, 42
            push rdi
            mov rcx, Msg
            push rcx
            call _printf
            add rsp, 4 * 8
            pop rcx
            pop rcx
            pop rcx
            pop rcx


            mov rax, 1
            xor rbx, rbx
            int 0x80

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
;---------------------------------------------------------- 
; Printf
;  
; Entry: LAST PUSH STR OUT
; Note:  RSI = cur address in buffer
;        R8 = cur argument ptr in stack
;        R9 = save reg
; Exit:  RAX
; Destr: RBX
;---------------------------------------------------------- 

%macro      num_print 2
            push rbx
            push rdx
            push rdi
            push rax
            push rcx

            mov bl, %1
            mov cl, %2
            mov rdi, rsi
            mov rdx, [r8]
            ;cmp rdx, 0
            test rdx, rdx
            jnl %%gocall
            push ax
            mov al, '-'
            mov [rsi], al
            neg rdx
            pop ax
            add rsi, 1
            add rdi, 1
%%gocall:
            call Itoa
            add rsi, rax

            pop rcx
            pop rax
            pop rdi
            pop rdx
            pop rbx

            add r8, 8
            jmp repeat
%endmacro
global _printf
_printf:
            pop rax

            push r9
            push r8
            push rcx
            push rdx
            push rsi
            push rdi
            ;xor rax, rax

            push rax
            xor rax, rax

            push rbp
            mov rbp, rsp

            push r9
            push r8
            push rsi
            push rcx
            push rbx
            push rdi

            mov rsi, buffer
            mov rdi, [rbp + 16] ;ptr of str
            lea r8, [rbp + 24]
            ;mov r8, rbp
            ;add r8, 8


repeat:
;-------------------------------------------------
            mov r9, rdi

            mov al, 0
            cmp [rdi], al
            je return

            mov al, '%'
            cmp [rdi], al
            je .@check
.@while:             
            add rdi, 1
            mov al, 0
            cmp [rdi], al
            je last_copy
            mov al, '%'
            cmp [rdi], al
            jne .@while
.@skip:             
            mov rax, rdi
            mov rdi, r9
;----------------------------------------------- if found % programm is here and copy all before this
            push rbx
            push rdx
            push rdi

            xor rbx, rbx
            mov rbx, rax 
            sub rbx, rdi
            mov rdx, rdi
            mov rdi, rsi
            call Strncpy
            add rsi, rbx

            pop rdi
            pop rdx
            pop rbx
            mov rdi, rax
;-------------------------------------------------work with symbol after % in switch 
.@check:
            mov rax, rdi
            add rdi, 2
;-------------------------------------------------switch with find symbol
            xor rcx, rcx
            ;mov r9, table
            xor r9, r9
            movzx r9, byte [rax + 1]
            cmp r9, '%'
            jne .@switch
            jmp pr_print 
;-------------------------------------------------
.@switch:
            sub r9, 'b'
            mov rcx, [jump_table + r9 * 8]
            jmp rcx
            jmp return

d_print:
            num_print 10, 0 

x_print:
            num_print 16, 4 

b_print:
            num_print 2, 1 

o_print:
            num_print 8, 3 

s_print:
            push rdi
            push rbx
            push rax
            push rdx

            mov rdi, [r8]
            mov bl, 0
            call Strchr
            xor rbx, rbx
            mov rbx, rax
            sub rbx, rdi
            mov rdx, rdi
            mov rdi, rsi
            call Strncpy
            add rsi, rbx

            pop rdx
            pop rax
            pop rbx
            pop rdi

            add r8, 8
            jmp repeat

c_print:
            push ax
            mov al, [r8]
            mov [rsi], al
            pop ax
            add rsi, 1

            add r8, 8
            jmp repeat
symb_print:
            push cx
            mov cl, '%'
            mov [rsi], cl
            add rsi, 1
            mov cl, [rax + 1]
            mov [rsi], cl
            pop cx
            add rsi, 1

            ;add r8, 8
            jmp repeat
pr_print:
            push ax
            mov al, '%'
            mov [rsi], al
            pop ax
            add rsi, 1
            jmp repeat

last_copy:
            push rdx
            push rdi
            push rbx

            xor rbx, rbx
            mov rbx, rdi
            sub rbx, r9
            mov rdx, r9
            mov rdi, rsi
            call Strncpy

            add rsi, rbx
            pop rbx
            pop rdi
            pop rdx

            jmp return

return:
            sub rsi, buffer
            mov rax, rsi
            mov rcx, buffer
            mov rdx, rsi
            call _print

            pop rdi
            pop rbx
            pop rcx
            pop rsi
            pop r8
            pop r9

            pop rbp
            ret
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
;---------------------------------------------------------- 
; Print
;  
; Entry: RDX - length
;        CX - str ptr
; Exit:  None 
; Destr: RAX, RBX
;---------------------------------------------------------- 
_print:
            push rax
            push rbx

            mov rax, 4 
            mov rbx, 1 
            int 0x80

            pop rbx
            pop rax
            ret
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
;---------------------------------------------------------- 
; StrchrInclude
;  
; Entry: RDI - ptr of string
;        BL - symbol
; Note:  
; Exit:  AX
; Destr: DI
;---------------------------------------------------------- 
Strchr:
                    push rdi
                    call StrchrInclude
                    pop rdi
                    ret


StrchrInclude:     
                    mov al, bl
                    cmp [rdi], al
                    je .@ret
.@while:             
                    add rdi, 1
                    cmp [rdi], al
                    jne .@while
.@ret:             
                    mov rax, rdi
                    ret 
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
;---------------------------------------------------------- 
; StrncpyInclude
;  
; Entry: DX - ptr of first string
;        DI - ptr of sec string
;        BX - length
; Note:  
; Exit:  AX
; Destr: DI, CX
;---------------------------------------------------------- 

Strncpy:

                    push rdi
                    push rdx
                    push rax
                    push rbx
                    call StrncpyInclude
                    pop rbx
                    pop rax
                    pop rdx
                    pop rdi

                    ret



StrncpyInclude:
.@while:             
                    mov byte al, [rdx]
                    mov byte [rdi], al

                    add rdi, 1
                    add rdx, 1
                    sub bx, 1

                    cmp al, 0
                    je .@ret
                    
                    cmp bx, 0
                    jne .@while

.@ret:
                    ret 

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
;---------------------------------------------------------- 
; ItoaInclude
;  
; Entry: DI - ptr of string
;        BL - type of num
;        DX - NUM
;        Cl -shift type
; Note:  
; Exit:  AX - num words
; Destr: CX, BX, DX
;---------------------------------------------------------- 

Itoa:
                    push rdx
                    push rbx
                    push rcx

                    cmp bl, 10d
                    je .@Itoa10d
                    jne .@Itoa2d
.@Itoa10d:            
                    call ItoaInclude10d
                    jmp .@ret

.@Itoa2d:
                    call ItoaInclude2xD
                    jmp .@ret

.@ret:
                    pop rcx
                    pop rbx
                    pop rdx

                    ret


ItoaInclude10d:
                    push rsi
                    xor rsi, rsi
                    mov sil, bl
                    mov rcx, rdi
; div rdx eax = rax - ?????????????? rdx - ??????????????
.@while:
                    mov eax, edx
                    xor rdx, rdx
                    div rsi;bl
                    
                    add rdx, '0'
                    mov [rdi], dl
                    add rdi, 1

                    mov rdx, rax
                    cmp rax, 0
                    ja .@while

                    mov rax, rdi
                    sub rax, rcx
                    mov rbx, rax
                    mov rdi, rcx

                    call SwapElements

.@ret:              
                    mov rdi, rcx
                    pop rsi
                    ret 


ItoaInclude2xD:
                    mov rax, rdx
                    push rdi

                    xor ch, ch
                    cmp cl, 4
                    je .@SetCh4
                    cmp cl, 3
                    je .@SetCh3
                    jmp .@SetCh1

.@SetCh4:           
                   mov ch, 1111b 
                   jmp .@while

.@SetCh3:
                   mov ch, 111b 
                   jmp .@while
.@SetCh1:
                   mov ch, 1b 

.@while:             
                    mov rdx, rax ; save result = ax
                    and dl, ch ;bl ; ?????????? ??????????????

                    shr rax, cl

                    add dl, '0'
                    cmp dl, '9'
                    jbe .@SkipLet
                    sub dl, '0'
                    add dl, 'A'
                    sub dl, 10d

.@SkipLet:
                    mov [rdi], dl
                    add rdi, 1

                    cmp al, 0
                    ja .@while

                    pop rcx

                    mov rbx, rdi
                    sub rbx, rcx
                    mov rax, rbx
                    mov rdi, rcx

                    call SwapElements

.@ret:              
                    ;mov rax, rdi
                    ;sub rax, rcx
                    mov rdi, rcx
                    ret 

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------



;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
;---------------------------------------------------------- 
; SwapElementsInclude
;  
; Entry: DI - ptr of string
;        ES - segment
;        BX - length
; Note:  
; Exit:  NONE
; Destr: CX, AX, DI, BX
;---------------------------------------------------------- 
SwapElements:
                            push rcx
                            push rax
                            push rdi
                            push rbx

                            call SwapElementsInclude

                            pop rbx
                            pop rdi
                            pop rax
                            pop rcx

                            ret 

SwapElementsInclude:
                            sub bx, 1
                            cmp bx, 0
                            je .@ret
.@while:                            
                            mov cx, [rdi]
                            add rdi, rbx
                            mov ax, [rdi]
                            mov [rdi], cl
                            sub rdi, rbx
                            mov [rdi], al

                            add rdi, 1
                            sub bx, 2

                            cmp bx, 1
                            jge .@while
.@ret:             
                            ret 

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
section     .data

Msg:        db "num %b in d, %x in x, %o in o, %b in b", 0x0A

str:        db "my ratdnfisbfi$"

table:      db "dxobcs%"
table_len   equ $-table

jump_table:
            dq b_print
            dq c_print
            dq d_print
            times 'o'-'d'-1   dq (symb_print) 
            dq o_print
            times 's' - 'o'-1 dq (symb_print)
            dq s_print
            times 'x' - 's'-1 dq (symb_print)
            dq x_print

buffer:     db 64 dup (0) 