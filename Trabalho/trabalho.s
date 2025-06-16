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
    sw ra, 12(sp)      # salva ra no topo da pilha (offset 12)
    mv t1, a0

    loop:
        lb t0, 0(t1)
        beqz t0, acabou
        li a0, 1
        mv a1, t1
        li a2, 1
        li a7, 64
        ecall
        addi t1, t1, 1
        j loop

    acabou:
        li a0, 1
        la a1, barN
        li a2, 1
        li a7, 64
        ecall
        lw ra, 12(sp)      # restaura corretamente o ra
        addi sp, sp, 16
        ret
