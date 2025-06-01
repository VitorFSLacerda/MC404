.data
.align 2
barN: .byte '\n'
msg: .asciz "Mover disco _ da torre _ para a torre _\0"

.globl puts
.globl gets
.globl atoi
.globl itoa
.globl exit
.globl fatorial_recursive
.globl fibonacci_recursive
.globl torre_de_hanoi

.text
.align 2

# int factorial(int n)
# Entrada: a0
# Retorno: a0

# int fatorial_recursive(int num)
fatorial_recursive:
    addi sp, sp, -16       # reservar espaço na pilha
    sw ra, 12(sp)          # salvar ra (endereço de retorno)  
    sw a0, 8(sp)           # salvar n original 3 - 2 - 1
    li t0, 1
    ble a0, t0, base_case  # if (n <= 1) return 1
    addi a0, a0, -1        # a0 = n - 1
    jal fatorial_recursive         # chamada recursiva, resultado em a0
    lw t1, 8(sp)           # recuperar n original
    mul a0, a0, t1         # a0 = factorial(n - 1) * n
    j end_factorial

base_case:
    li a0, 1

end_factorial:
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

fibonacci_recursive:
    addi sp, sp, -16       # espaço na pilha
    sw ra, 12(sp)          # salvar ra
    sw a0, 8(sp)           # salvar n
    li t0, 1
    beq a0, zero, fib_zero      # fib = 2
    beq a0, t0, fib_um
    # calcular fib(n - 1)
    addi a0, a0, -1
    jal fibonacci_recursive
    sw a0, 4(sp)           # salva parte de um valor
    # recuperar n original
    lw a0, 8(sp)
    addi a0, a0, -2
    jal fibonacci_recursive
    # recupera
    lw t1, 4(sp)
    add a0, a0, t1         # a0 = fib(n - 1) + fib(n - 2)
    j fib_fim

fib_zero:
    li a0, 0
    j fib_fim

fib_um:
    li a0, 1

fib_fim:
    lw ra, 12(sp)
    addi sp, sp, 16
    ret

# void torre_de_hanoi(int num, char de, char auxiliar, char ate, char* str);
# void torre_de_hanoi(a0, a1, a2, a3, a4)
torre_de_hanoi:
    addi sp, sp, -32
    sw ra, 28(sp)
    sw a0, 24(sp)
    sw a1, 20(sp)
    sw a2, 16(sp)
    sw a3, 12(sp)
    sw a4, 8(sp)
    li t0, 1
    beq a0, t0, hanoi_base

    # hanoi(n-1, de, ate, aux, str)
    addi a0, a0, -1
    lw a1, 20(sp)
    lw a2, 12(sp)
    lw a3, 16(sp)
    lw a4, 8(sp)
    jal torre_de_hanoi
    # imprime movimento
    lw a0, 24(sp)       # num
    lw a1, 20(sp)       # de
    lw a2, 12(sp)       # ate
    la t0, msg          # ponteiro para a string base
    # converter número para ASCII
    addi t3, a0, 48     # '0' + num
    sb t3, 12(t0)       # substitui primeiro '_'
    sb a1, 23(t0)       # substitui segundo '_': origem
    sb a2, 38(t0)       # substitui terceiro '_': destino
    la a0, msg
    jal puts
    # hanoi(n-1, aux, de, ate, str)
    lw a0, 24(sp)
    addi a0, a0, -1
    lw a1, 16(sp)
    lw a2, 20(sp)
    lw a3, 12(sp)
    lw a4, 8(sp)
    jal torre_de_hanoi
    j hanoi_end

hanoi_base:
    lw a0, 24(sp)       # num
    lw a1, 20(sp)       # de
    lw a2, 12(sp)       # ate
    la t0, msg          # ponteiro para a string
    addi t3, a0, 48     # '0' + num → caractere ASCII
    sb t3, 12(t0)       # substitui '_' do número
    sb a1, 23(t0)       # substitui '_' da torre origem
    sb a2, 38(t0)       # substitui '_' da torre destino
    la a0, msg
    jal puts

hanoi_end:
    lw ra, 28(sp)
    addi sp, sp, 32
    ret

# void puts(char* s)
puts:
    addi sp, sp, -16
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
    addi sp, sp, 16
    ret

# void gets(char* buffer)
gets:
    addi sp, sp, -16
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
    addi sp, sp, 16
    ret

# int atoi(char* str)
atoi:
    addi sp, sp, -16
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
    addi sp, sp, 16
    ret


# char* itoa(int value, char* buffer, int base)
# a0 = valor
# a1 = buffer
# a2 = base

itoa:
    addi sp, sp, -16
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
    addi sp, sp, 16
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
