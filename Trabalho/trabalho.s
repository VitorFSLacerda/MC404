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

# void gets(char* buffer)
gets:
    addi sp, sp, -16
    sw ra, 12(sp)
    mv a1, a0            # ponteiro para onde salvar os caracteres
    li t1, 0             # contador de '\n'

loop:
    li a0, 0             # stdin
    mv a1, a1            # onde salvar o caractere
    li a2, 1
    li a7, 63
    ecall

    lb t5, 0(a1)         # lê o caractere salvo
    li t0, 10            # '\n' == 10
    beq t5, t0, conta_nl # se for '\n', contar
    addi a1, a1, 1       # avança para próximo caractere
    j loop

conta_nl:
    addi t1, t1, 1       # incrementa contador
    li t2, 3
    beq t1, t2, fim      # se encontrou 3 '\n', parar
    addi a1, a1, 1       # senão, continua lendo
    j loop

fim:
    sb zero, 0(a1)       # adiciona '\0' ao final
    lw ra, 12(sp)
    addi sp, sp, 16
    ret


