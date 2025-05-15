.globl _start

_start:
    jal main


exit:
    li a0, 0
    li a7, 93
    ecall


main:
    call read
    la t0, input  # ponteiro para o buffer
    call manage
    call calculation
    call string
    call write
	j exit


manage:
    li t1, 0              # número parcial
    li t2, 0              # contador de números encontrados


loop:
    lb t3, 0(t0)
    addi t0, t0, 1        # avança ponteiro

    li t4, 10             # '\n'
    beq t3, t4, endNumber
    li t4, 32             # espaço
    beq t3, t4, endNumber
    li t5, 10
    li t4, 48
    mul t1, t1, t5 # t1 = 0
    sub t3, t3, t4  
    add t1, t1, t3  
    j loop


endNumber:
    li t4, 0
    beq t2, t4, saveS0
    li t4, 1
    beq t2, t4, saveS1
    li t4, 2
    beq t2, t4, saveS2


saveS0:
    mv s0, t1
    li t1, 0
    addi t2, t2, 1
    j loop


saveS1:
    mv s1, t1
    li t1, 0
    addi t2, t2, 1
    j loop


saveS2:
    mv s2, t1
    li t1, 0
    addi t2, t2, 1
    ret


calculation:
    mul t5, s0, s2
	div t5, t5, s1
	mv a0, t5
	ret


string:
    la t0, result
    li t2, 10
    li t3, 10
    blt a0, t3, oneString
    div t1, a0, t2     # t1 = dezena
    rem t2, a0, t2     # t2 = unidade
    addi t1, t1, 48
    addi t2, t2, 48
    sb t1, 0(t0)
    sb t2, 1(t0)
    sb t3, 2(t0)    
    li a2, 3     
    ret


oneString:
    addi t1, a0, 48
    sb t1, 0(t0)
    li t3, 10
    sb t3, 1(t0)   
    li a2, 2       
    ret


read:
    li a0, 0
    la a1, input
    li a2, 9
    li a7, 63
    ecall
    ret


write:
    li a0, 1
    la a1, result
    li a7, 64
    ecall
    ret


.bss
input: .skip 9
result: .skip 3