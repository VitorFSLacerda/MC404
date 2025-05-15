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
    la s0, vetor  # s0 = ponteiro para o vetor de saída
    li s1, 0      # contador de iterações (até 3)

    call loop_manage


    call loop_limitante



    la s0, vetor  # volta s0 para inicio do vetor

    
    la s1, integrais
    li s7, 0   # contador de iterações (até 3)
    call integraisMenores




    la s1, integrais
    call somaTodasIntegrais


    call string
    call write
    j exit

//////////////////////////////////////////////////////////////////////
loop_manage:
    li t1, 0              # zera número parcial
    lb t2, 0(t0)          # lê símbolo (char)
    addi t0, t0, 2        # avança 2 posições (símbolo + separador)


loop_read_number:

    lb t3, 0(t0)          # lê próximo caractere
    addi t0, t0, 1        # avança ponteiro
    li t4, 10             # '\n'
    beq t3, t4, end_number_read  # se for \n, acabou o número
    li t5, 10             # base 10
    li t4, 48             # ASCII de '0'
    mul t1, t1, t5        # t1 = t1 * 10
    sub t3, t3, t4        # t3 = t3 - 48 (ASCII -> número)
    add t1, t1, t3        # t1 = t1 + novo dígito
    j loop_read_number


end_number_read:

    sb t2, 0(s0)          # salva símbolo no vetor de saída
    addi s0, s0, 1        # avança ponteiro de escrita
    sw t1, 0(s0)          # salva número (32 bits)
    addi s0, s0, 4        # avança 4 bytes no vetor
    addi s1, s1, 1        # iteração++
    li t4, 3
    bne s1, t4, loop_manage  # se não chegou em 3, continua
    ret
//////////////////////////////////////////////////////////////////////



somaTodasIntegrais:

    lw t2, 0(s1)
    addi s1, s1, 4
    lw t3, 0(s1)
    addi s1, s1, 4
    lw t4, 0(s1)
    add t2, t2, t3
    add a0, t2, t4
    ret



# b wwww b wwww b wwww wwww wwww
///////////////////////////////////////////////////////
loop_limitante:
    li t1, 0


loop:

    lb t2, 0(t0)          # lê próximo caractere
    addi t0, t0, 1        # avança ponteiro
    li t4, 10             # '\n'
    beq t2, t4, endNumber # se for \n, acabou o número
    li t4, 32             # espaço
    beq t2, t4, putNumber
    li t5, 10             # base 10
    li t4, 48             # ASCII de '0'
    mul t1, t1, t5        # t1 = t1 * 10
    sub t2, t2, t4        # t2 = t2 - 48 (ASCII -> número)
    add t1, t1, t2        # t1 = t1 + novo dígito
    j loop


putNumber:

    sw t1, 0(s0)          # salva número (32 bits)
    addi s0, s0, 4        # avança 4 bytes no vetor
    j loop_limitante


endNumber:

    sw t1, 0(s0)          # salva número (32 bits)
    ret
/////////////////////////////////////////////////////////////////

integraisMenores:

    lb t4, 0(s0)
    addi s0, s0, 1     # calcula s1 = s0 + 1 (posição onde começa o número)
    lw t1, 0(s0)       # carrega 4 byte da memória para t1
    addi t1, t1, 1     #Pega o valor no vetor e soma 1
    sw t1, 0(s0)
    addi s0, s0, 4
    j pow



# integraisMenores:

#     lb t4, 0(s2)
#     addi s2, s2, 1     # calcula s1 = s0 + 1 (posição onde começa o número)
#     lw t1, 0(s2)       # carrega 4 byte da memória para t1
#     addi t1, t1, 1     #Pega o valor no vetor e soma 1
#     sw t1, 0(s2)
#     addi s2, s2, 4
#     j pow


# Suponha:
# a0 = base (a)
# a1 = expoente (b)
pow:
    la s3, vetor
    addi s3, s3, 15     #quero pegar os ultimos 2 numeros , os ultimos 8 bytes, cada 4 bytes é um numero
    lw t2, 0(s3)        # base X que sera multiplicada n vezes,
    addi s3, s3, 4
    lw t3, 0(s3)
    li t5, 1
    li t6, 1
    mv a7, t1


loop_pow:
    beqz t1, sinal   # se expoente == 0, termina
    mul t5, t5, t2     # resultado = resultado * base
    mul t6, t6, t3     # resultado = resultado * base
    addi t1, t1, -1    # expoente -= 1
    j loop_pow


sinal:

    li t1, 45
    div t5, t5, a7
    div t6, t6, a7
    beq t4, t1, negativoIntegral #se for negativo muda
    j soma




negativoIntegral:

    li t1, -1
    mul t5, t5, t1
    mul t6, t6, t1


soma:

    sub t5, t6, t5
    sw t5, 0(s1)
    addi s1, s1, 4
    addi s7, s7, 1
    li t1, 3
    blt s7, t1, integraisMenores
    ret


string:

    la t0, result   # ponteiro para onde salvar string
    li t4, 0        # contador de caracteres
    li t5, 10       # constante 10
    bltz a0, negativo


positivo:

    mv t1, a0       # t1 = a0 (número positivo)
    j convert


negativo:

    li t6, 45       # ASCII de '-'
    sb t6, 0(t0)    # salva '-' no começo
    addi t0, t0, 1  # avança ponteiro de escrita
    neg t1, a0      # t1 = -a0 (inverte o sinal)


convert:
    # t1 agora tem o número positivo para converter
    li t3, 0        # índice de escrita


convert_loop:

    rem t2, t1, t5  # t2 = t1 % 10 (último dígito)
    addi t2, t2, 48 # transforma dígito em ASCII
    sb t2, 0(t0)    # salva o caractere na string
    addi t0, t0, 1  # avança ponteiro
    div t1, t1, t5  # t1 = t1 / 10
    addi t3, t3, 1  # conta quantos dígitos gravou
    bnez t1, convert_loop # continua se ainda tiver dígitos
    la s5, resultado
    mv t1, t3

   
invert:

    beqz t1, final      # se t1 == 0, terminou de inverter
    addi t0, t0, -1     # volta 1 posição no vetor original (porque t0 estava no final)
    lb t2, 0(t0)        # lê 1 byte do vetor original
    sb t2, 0(s5)        # salva esse byte na posição atual do vetor destino (s5)
    addi s5, s5, 1      # avança s5 (vetor destino)
    addi t1, t1, -1     # decrementa contador de caracteres restantes
    j invert


final:

    li t0, 10         # Carrega o valor do '\n' (10 em ASCII)
    sb t0, 0(s5)      # Salva '\n' na posição atual apontada por s5
    addi t3, t3, 1    # Soma 1 no contador de caracteres (t3 = t3 + 1)
    mv a2, t3         # Prepara o tamanho final em a2
    ret


read:

    li a0, 0
    la a1, input
    li a2, 24
    li a7, 63
    ecall
    ret


write:

    li a0, 1
    la a1, resultado
    li a7, 64
    ecall
    ret


.bss
vetor: .skip 23 #Salva os simbolos e os numeros 1 byte e depois 4 bytes e por fim nos ultimos 2, 8bytes 2 numeros
integrais: .skip 12 #Salva 3 inteiros, ou seja, 4bytes * 3
input: .skip 24 #Apenas le a entrada
result: .skip 30
resultado: .skip 30 #string final invertida e com \n

