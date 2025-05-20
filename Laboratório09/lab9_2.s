.data
.align 2
barN: .byte '\n'

.globl linked_list_search
.globl puts
.globl gets
.globl atoi
.globl itoa
.globl exit


.text
.align 2

# Busca na lista ligada: recebe ponteiro em a0 e valor alvo em a1
linked_list_search:
    addi sp, sp, -16
    sw ra, 0(sp)
    sw a0, 4(sp)
    sw a1, 8(sp)
    li t6, 0           # contador de posições

loop1:
    beqz a0, naoAchou  # fim da lista
    lw t0, 0(a0)       # valor1
    lw t1, 4(a0)       # valor2
    add t2, t0, t1     # soma
    beq t2, a1, achou  # achou?
    addi t6, t6, 1     # conta posição
    lw a0, 8(a0)       # próximo nó
    j loop1

naoAchou:
    lw ra, 0(sp)
    addi sp, sp, 16
    li a0, -1
    ret

achou:
    lw ra, 0(sp)
    addi sp, sp, 16
    mv a0, t6
    ret

# void puts(char* s)
puts:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw a0, 4(sp)
    mv t1, a0

loop2:
    lb t0, 0(t1)
    beqz t0, acabou
    li a0, 1
    mv a1, t1
    li a2, 1
    li a7, 64
    ecall
    addi t1, t1, 1
    j loop2

acabou:
    li a0, 1
    la a1, barN
    li a2, 1
    li a7, 64
    ecall
    lw ra, 0(sp)
    lw a0, 4(sp)
    addi sp, sp, 8
    ret

# void gets(char* buffer)
gets:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw a0, 4(sp)
    mv a1, a0

loop3:
    li a0, 0       # stdin
    mv a1, a1      # onde salvar o caractere
    li a2, 1
    li a7, 63
    ecall

    lb t5, 0(a1)
    li t0, 10      # '\n'
    beq t5, t0, barraN
    addi a1, a1, 1
    j loop3

barraN:
    sb zero, 0(a1)   # adiciona '\0'
    lw ra, 0(sp)
    lw a0, 4(sp)
    addi sp, sp, 8
    ret

# int atoi(char* str)
atoi:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw a0, 4(sp)

    li t0, 1         # sinal positivo por padrão
    li t4, 0         # acumulador

loop4:
    lb t1, 0(a0)
    li t2, 32
    beq t1, t2, skipEspaco
    li t2, 45
    beq t1, t2, negativo
    j convertInt

skipEspaco:
    addi a0, a0, 1
    j loop4

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
    addi sp, sp, 8
    ret

# char* itoa(int value, char* buffer)
# a0 = inteiro
# a1 = buffer

itoa:
    addi sp, sp, -16
    sw ra, 0(sp)
    sw a1, 4(sp)         # salvar ponteiro original do buffer
    mv t0, a0            # valor
    li t6, 0             # flag negativo (0 = positivo)

    bltz t0, negati    # se valor < 0, vai pra negativo

continua:
    li t2, 10            # divisor
    mv t1, a1            # ponteiro de escrita

itoa_loop:
    rem t3, t0, t2
    addi t3, t3, 48      # converter para ASCII
    sb t3, 0(t1)
    addi t1, t1, 1
    div t0, t0, t2
    bnez t0, itoa_loop

    beqz t6, itoa_termina # se não for negativo, pula

    li t4, 45            # '-'
    sb t4, 0(t1)
    addi t1, t1, 1

itoa_termina:
    sb zero, 0(t1)       # termina string

    # inverter string
    lw a1, 4(sp)         # recupera início do buffer
    mv t2, a1
    add t3, t1, zero     # t3 = ponteiro final
    addi t3, t3, -1      # último caractere antes do '\0'

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
    addi sp, sp, 16
    mv a0, a1             # retorna ponteiro para string
    ret

negati:
    li t6, 1
    neg t0, t0
    j continua


# Encerrar o programa
exit:
    li a0, 0
    li a7, 93
    ecall
