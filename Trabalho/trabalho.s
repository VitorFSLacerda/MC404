.data
.align 2
barN: .byte '\n'

.globl puts
.globl gets
.globl atoi
.globl itoa
.globl exit


.text
.align 2

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
        beq t1, t2, fim      # se encontrou 3 '\n', parar
        addi a1, a1, 1       # senão, continua lendo
        j loop2

    fim:
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


# Encerrar o programa
exit:
    li a0, 0
    li a7, 93
    ecall