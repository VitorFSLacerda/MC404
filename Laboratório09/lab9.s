.data 
.align 2
barN: .byte '\n'


.globl linked_list_search
.globl puts
.globl gets
.globl atoi
.globl itoa
.globl exit
.globl _start

.text
.align 2


linked_list_search:
    addi sp, sp, -16
    sw ra, 0(sp)
    sw a0, 4(sp)
    sw a1, 8(sp)
    li t6, 0

loop1:
    beqz t0, naoAchou
    lw t0, 0(a0)
    lw t1, 4(a0)
    add t0, t0, t1  
    beq t0, a1, achou
    addi t6, t6, 1
    lw t3, 8(a0)
    mv a0, t3
    j loop1

naoAchou:
    lw a1, 8(sp)
    lw ra, 0(sp)
    addi sp, sp, 16
    li a0, -1
    ret

achou:
    lw a1, 8(sp)
    lw ra, 0(sp)
    addi sp, sp, 16
    mv a0, t6
    ret

# void puts(vsagdvsa, sadsa)
puts:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw a0, 4(sp)
    mv a1, a0

loop2:
    lb t0, 0(a1)
    beqz t0, acabou
    li a0, 1
    li a2, 1
    li a7, 64
    ecall
    addi a1, a1, 1
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


gets:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw a0, 4(sp)
    mv a1, a0

loop3:
    
    li a0, 0
    li a2, 1
    li a7, 63
    ecall
    li t0, 10
    lb t5, 0(a1)
    beq t5, t0, barraN
    addi a1, a1, 1
    j loop3

barraN:
    sb zero, 0(a1) 
    lw ra, 0(sp)
    lw a0, 4(sp)
    addi sp, sp, 8
    ret

atoi:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw a0, 4(sp)

loop4:
    li t0, 32   
    lb t1, 0(a0)
    beq t1, t0, espaco
    li t0, 45
    beq t1, t0, negativo
    li t0, 1
    li t4, 0
    j convertInt

espaco:
    addi a0, a0, 1
    j loop4

negativo:
    li t0, -1

convertInt:

    lb t1, 0(a0)
    addi a0, a0, 1        # avança ponteiro

    beqz t1, terminou

    li t2, 10             # '\n'
    li t3, 48
    mul t4, t4, t2 #t4 = 0 , t2 = 10
    sub t1, t1, t3  # t3 = 48, t1 = caracter
    add t4, t4, t1  #t4 acumulador
    j convertInt
    
terminou:
    lw ra, 0(sp)
    mul t4, t4, t0
    mv a0, t4
    addi sp, sp, 8
    ret

itoa:

exit:
