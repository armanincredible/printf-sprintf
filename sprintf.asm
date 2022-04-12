section .text
global _start 
_start:     
            mov rcx, str
            push rcx
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
            mov rcx, buffer
            push rcx
            call _sprintf
            add rsp, 7 * 8
            pop rcx
            pop rcx
            pop rcx
            pop rcx
            pop rcx
            pop rcx
            pop rcx

            mov rdx, rax
            mov rcx, buffer
            mov rax, 4 
            mov rbx, 1 
            int 0x80

            mov rax, 1
            xor rbx, rbx
            int 0x80

;-----------------------------------------------------------------------------------------------------------------------------------------------------------------
;---------------------------------------------------------- 
; Sprintf
;  
; Entry: LAST PUSH STR IN
;        PRE-LAST PUSH STR OUT
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

%macro      str_copy 2

            push rbx
            push rdx
            push rdi

            xor rbx, rbx
            mov rbx, %1
            sub rbx, %2
            mov rdx, %2
            mov rdi, rsi
            call Strncpy
            add rsi, rbx

            pop rdi
            pop rdx
            pop rbx
%endmacro

_sprintf:
            sub rsp, 1
            mov rax, [rsp]

            push rdi
            push rdi
            push rdx
            push rcx
            push r8
            push r9
            mov [rsp], rax
            xor rax, rax

            push rbp
            mov rbp, rsp

            push r9
            push r8
            push rsi
            push rcx
            push rbx
            push rdi

            mov rsi, [rbp + 16]
            mov rdi, [rbp + 24] 
            lea r8, [rbp + 32]

;-------------------------------------------------
repeat:
            mov r9, rdi

            mov al, '$'
            cmp [rdi], al
            je return

            mov al, '%'
            cmp [rdi], al
            je .@check
.@while:             
            add rdi, 1
            mov al, '$'
            cmp [rdi], al
            je last_copy
            mov al, '%'
            cmp [rdi], al
            jne .@while
.@skip:             
            mov rax, rdi
            mov rdi, r9
;----------------------------------------------- if found % programm is here and copy all before this
            str_copy rax, rdi
            mov rdi, rax
;-------------------------------------------------work with symbol after % in switch 
.@check:
            mov rax, rdi
            add rdi, 2
;-------------------------------------------------switch with find symbol
            mov cx, table_len
            mov r9, table
            mov bl, [rax + 1]
.@take_ptr:
            cmp [r9], bl
            je .@switch
            add r9, 1
            sub cx, 1
            cmp cx, 0
            jne .@take_ptr
;-------------------------------------------------
.@switch:
            sub r9, table
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
            push rax

            mov rdi, [r8]
            mov bl, '$'
            call Strchr

            str_copy rax, rdi

            pop rax
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
pr_print:
            push ax
            mov al, '%'
            mov [rsi], al
            pop ax
            add rsi, 1
            jmp repeat
last_copy:
            str_copy rdi, r9
            jmp return
return:
            sub rsi, [rbp + 16]
            mov rax, rsi

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
;        RCX - str ptr
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

                    cmp al, '$'
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
                    and dl, ch ;bl ; найти остаток

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

Msg:        db "num %d in d, %x in x, %o in o, %b in b; %% %s", 0x0A, '$'

str:        db "im here man$"

table:      db "dxobcs%"
table_len   equ $-table

jump_table  dq d_print
            dq x_print
            dq o_print
            dq b_print
            dq c_print
            dq s_print
            dq pr_print

buffer:     db "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"