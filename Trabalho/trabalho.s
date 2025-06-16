.data
.align 2
    barN: .byte '\n'

.globl _start
.globl puts
.globl gets
.globl atoi
.globl itoa
.globl exit
.globl parse_numeros

.bss
    entrada: .skip 6000
    arquiteturaDaRede: .skip 6000
    buffer: .skip 32
    copia: .skip 100


.text
.align 2


_start:

    la a0, entrada
    jal gets
    la a1, arquiteturaDaRede


    jal manager


    # mv t0, a0
    # la a0, entrada
    # add a0, t0, a0

    # char* itoa(int value, char* buffer, int base)
    # a0 = valor
    # a1 = buffer
    # a2 = base
    la a1, arquiteturaDaRede
    lw a0, 0(a1)       # valor a converter
    la a1, buffer     # ponteiro para o buffer onde será escrito o número em string
    li a2, 10         # base decimal
    jal itoa          # chama itoa (retorna ponteiro para buffer em a0)
    jal puts          # imprime a string no buffer




    jal exit


manager:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw a0, 8(sp)    # salva ponteiro para string original
    sw a1, 4(sp)    # salva ponteiro para vetor de inteiros

    loop_manager:
        lw a0, 8(sp)        # carrega ponteiro atual da string
        li t1, 123           # '{'
        lb t0, (a0)   
        beq t0, t1, fim_manager


        jal parse_numeros   # parseia um número, salva em "copia" e retorna novo ponteiro da string em a0
        sw a0, 8(sp)        # atualiza ponteiro da string

        la a0, copia        # ponteiro para string do número
        jal atoi            # converte para inteiro

        lw a1, 4(sp)        # carrega ponteiro atual do vetor
        sw a0, 0(a1)        # salva valor convertido
        addi a1, a1, 4      # anda vetor
        sw a1, 4(sp)        # salva novo ponteiro

        j loop_manager

    fim_manager:
        lw ra, 12(sp)
        addi sp, sp, 16
        ret



parse_numeros:
    addi sp, sp, -16
    sw ra, 12(sp)

    mv t0, a0          # ponteiro atual na string
    la a4, copia       # ponteiro para buffer copia

    loop_parse:
        lb t3, 0(t0)
        li t4, 44          # ','
        li t5, 10          # '\n'

        beq t3, t4, fim
        beq t3, t5, fim
        beqz t3, fim       # fim de string por segurança

        sb t3, 0(a4)
        addi a4, a4, 1
        addi t0, t0, 1
        j loop_parse

    fim:
        sb zero, 0(a4)
        addi t0, t0, 1     # avança além do separador
        mv a0, t0          # retorna novo ponteiro da string em a0
        lw ra, 12(sp)
        addi sp, sp, 16
        ret




# void puts(char* s)
puts:
    addi sp, sp, -16
    sw ra, 12(sp)
    mv t1, a0

    loop1:
        lb t0, 0(t1)
        beqz t0, acabou
        li a0, 1
        mv a1, t1
        li a2, 1
        li a7, 64
        ecall
        addi t1, t1, 1
        j loop1

    acabou:
        li a0, 1
        la a1, barN
        li a2, 1
        li a7, 64
        ecall
        lw ra, 12(sp)
        addi sp, sp, 16
        ret


# void gets(char* buffer)
gets:
    addi sp, sp, -16
    sw ra, 12(sp)
    mv a1, a0            # ponteiro para onde salvar os caracteres
    li t1, 0             # contador de '\n'

    loop2:
        li a0, 0             # stdin
        mv a1, a1            # onde salvar o caractere
        li a2, 1
        li a7, 63
        ecall

        lb t5, 0(a1)         # lê o caractere salvo
        li t0, 10            # '\n' == 10
        beq t5, t0, conta_nl # se for '\n', contar
        addi a1, a1, 1       # avança para próximo caractere
        j loop2

    conta_nl:
        addi t1, t1, 1       # incrementa contador
        li t2, 3
        beq t1, t2, fim2     # se encontrou 3 '\n', parar
        addi a1, a1, 1       # senão, continua lendo
        j loop2

    fim2:
        sb zero, 0(a1)       # adiciona '\0' ao final
        lw ra, 12(sp)
        addi sp, sp, 16
        ret


# int atoi(char* str)
atoi:
    addi sp, sp, -16
    sw ra, 0(sp)
    sw a0, 4(sp)

    li t0, 1         # sinal positivo por padrão
    li t4, 0         # acumulador

    loop3:
        lb t1, 0(a0)
        li t2, 32
        beq t1, t2, skipEspaco
        li t2, 45
        beq t1, t2, negativo
        j convertInt

    skipEspaco:
        addi a0, a0, 1
        j loop3

    negativo:
        li t0, -1
        addi a0, a0, 1
        j convertInt

    convertInt:
        lb t1, 0(a0)
        beqz t1, terminou
        li t2, 10
        li t3, 48
        blt t1, t3, terminou     # se menor que '0', termina
        li t5, 57
        bgt t1, t5, terminou     # se maior que '9', termina

        mul t4, t4, t2
        sub t1, t1, t3
        add t4, t4, t1
        addi a0, a0, 1
        j convertInt

    terminou:
        mul t4, t4, t0
        mv a0, t4
        lw ra, 0(sp)
        addi sp, sp, 16
        ret


# char* itoa(int value, char* buffer, int base)
# a0 = valor
# a1 = buffer
# a2 = base

itoa:
    addi sp, sp, -32
    sw ra, 0(sp)
    sw a1, 4(sp)          # salvar ponteiro original do buffer
    sw a2, 8(sp)          # salvar base
    mv t0, a0             # valor
    li t6, 0              # flag negativo

    bltz t0, nega

    continua:
        mv s0, a2             # s0 = base
        mv t1, a1             # ponteiro de escrita

    itoa_loop:
        rem t3, t0, s0
        li t2, 10
        bge t3, t2, converte_hex

        addi t3, t3, 48       # '0'..'9'
        j salva_digito

    converte_hex:
        addi t3, t3, 55       # 'A' = 65, 65 - 10 = 55

    salva_digito:
        sb t3, 0(t1)
        addi t1, t1, 1
        div t0, t0, s0
        bnez t0, itoa_loop

        beqz t6, itoa_termina

        li t4, 45             # '-'
        sb t4, 0(t1)
        addi t1, t1, 1

    itoa_termina:
        sb zero, 0(t1)

        # inverter string
        lw a1, 4(sp)          # início do buffer
        mv t2, a1
        add t3, t1, zero
        addi t3, t3, -1

    inverte_loop:
        bge t2, t3, fim_inverte
        lb t4, 0(t2)
        lb t5, 0(t3)
        sb t5, 0(t2)
        sb t4, 0(t3)
        addi t2, t2, 1
        addi t3, t3, -1
        j inverte_loop

    fim_inverte:
        lw ra, 0(sp)
        addi sp, sp, 32
        mv a0, a1
        ret

    nega:
        li t6, 1
        neg t0, t0
        j continua


# Encerrar o programa
exit:
    li a0, 0
    li a7, 93
    ecall