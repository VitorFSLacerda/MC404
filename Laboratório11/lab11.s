.data
base: .word 0xFFFF0100
tempo_curva: .word 2000      # Número de ciclos para manter a curva

.text
.globl _start

_start:
    # Carrega base address
    la t0, base
    lw t0, 0(t0)

    # Libera freio de mão
    li t1, 0
    sb t1, 0x22(t0)

    # Liga o motor para frente
    li t1, 1
    sb t1, 0x21(t0)

    # Inicializa contador de curva
    la t1, tempo_curva
    lw s0, 0(t1)

fase_curva:
    li t2, 20           # direção levemente para a direita
    sb t2, 0x20(t0)

    # Esperar GPS (pode usar como delay)
    li t3, 1
    sb t3, 0x00(t0)
espera_gps:
    lb t4, 0x00(t0)
    bne t4, zero, espera_gps

    addi s0, s0, -1
    bnez s0, fase_curva

    # Zera o volante após curva
    li t1, 0
    sb t1, 0x20(t0)

loop:
    # Mantém motor andando reto para sempre
    j loop
