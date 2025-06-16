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
    sw ra, 12(sp)         # Salva ra no topo da pilha
    mv t1, a0             # t1 aponta para o início da string
    li t2, 0              # t2 será o contador de '\n'

loop:
    lb t0, 0(t1)          # carrega byte da string
    beqz t0, acabou       # se for nulo, termina

    li t3, '\n'
    beq t0, t3, conta_nl  # se for '\n', incrementa contador
    j imprime

conta_nl:
    addi t2, t2, 1        # incrementa contador de '\n'
    li t4, 3
    beq t2, t4, acabou    # se já encontrou 3 '\n', termina

imprime:
    li a0, 1
    mv a1, t1
    li a2, 1
    li a7, 64
    ecall

    addi t1, t1, 1        # avança para o próximo caractere
    j loop

acabou:
    lw ra, 12(sp)         # restaura ra
    addi sp, sp, 16
    ret

