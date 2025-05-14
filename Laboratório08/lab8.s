.globl _start

.data
.align 2

input_file: .asciz "image.pgm"

.bss
.align 2

input: .skip 4109
vetorMSGOne: .skip 31
vetorMSGTwo: .skip 24

.text
.align 2

_start:
	jal main

exit:
	li a0, 0
	li a7, 93
	ecall

main:
	call read
	call manage
	call cifra
	call reinsere
	call desenha
	j exit

#Length is the key. Allan Turing#4881


desenha:
	li a0, 0          # x = 0
	li a1, 0          # y = 0
	la a5, input
	addi a5, a5, 13   # pular os 13 primeiros bytes, se necessário

lpD:
	# carregar cor do byte atual
	lbu t1, 0(a5)
	
	# expandir byte para ARGB (0xTTTTTTFF)
	mv t2, t1
	slli t2, t2, 8
	or t2, t2, t1
	slli t2, t2, 8
	or t2, t2, t1
	slli t2, t2, 8
	ori t2, t2, 0xFF

	# chamar setPixel
	mv a2, t2
	li a7, 2200
	ecall

	# avançar ponteiro de leitura
	addi a5, a5, 1

	# avançar x
	addi a0, a0, 1
	li t5, 64
	blt a0, t5, lpD  # se x < 64, continua na mesma linha

	# resetar x e avançar y
	li a0, 0
	addi a1, a1, 1
	blt a1, t5, lpD  # se y < 64, continua



reinsere:
	li t1, 0      	#contador de bytes
	li t2, 0      	# contador de bits (0 a 7)
	li t4, 128     	##### 10000000
	la a2, input
	la a3, vetorMSGTwo
	addi a2, a2, 2000   
	addi a2, a2, 1917   


lpTwo:

	li t3, 8
	bge t2, t3, proxByte
    
	li t3, 24
	bge t1, t3, end
    
	lbu t5, 0(a2)
	lbu t6, 0(a3)
    
	and t3, t4, t6  	# pego o bit da direita pra esquerda
	beqz t3, bitZero   	# sei que é zero
   
	#sei q é 1
    
	ori t5, t5, 1
	sb t5, 0(a2)
    
	# atualizar loop
    
	addi a2, a2, 1
	addi t2, t2, 1
	li t6, 2
	div t4, t4, t6  #coloco o 1 uma unidade para a direita
    
    
	j lpTwo

bitZero:
	#sei q é 0
	# 254
    
	andi t5, t5, 254
	sb t5, 0(a2)
    
	# atualizar loop
    
	addi a2, a2, 1
	addi t2, t2, 1
	li t6, 2
	div t4, t4, t6  #coloco o 1 uma unidade para a direita
    
    
	j lpTwo



proxByte:

	addi a3, a3, 1
	addi t1, t1, 1
	li t2, 0      	# contador de bits (0 a 7)
	li t4, 128     	##### 10000000

	j lpTwo





cifra:
	li t1, 0
	la a2, vetorMSGTwo

lp:
	li t3, 24
	bge t1, t3, end
	lbu t4, 0(a2)
    
	li t3, 65
	blt t4, t3, add   # se t4 < 65, pula
	li t3, 123
	bge t4, t3, add   # se t4 > 122, termina

	li t3, 90
	blt t4, t3, ascMai   # se t4 < 90, minuscula
	li t3, 97
	bge t4, t3, ascMen   # se t4 >= 97, maiscula
	j add


#[65, 90]
#[97, 122]

ascMen:

	addi t4, t4, -12
	li t3, 97
	li t5, 122
	blt t4, t3, redefine
	sb t4, 0(a2)
	j add

ascMai:

	addi t4, t4, -12
	li t3, 65
	li t5, 90
	blt t4, t3, redefine
	sb t4, 0(a2)
	j add

redefine:

	sub t3, t3, t4
	sub t3, t5, t3
	sb t3, 0(a2)
	j add


add:
	addi a2, a2, 1
	addi t1, t1, 1
	j lp


manage:
	li t0, 0      	# contador de bytes extraídos (0 a 54)
	li t2, 0      	# contador de bits (0 a 7)
	li t4, 0     	 
	la a2, input
	addi a2, a2, 13   

	la a3, vetorMSGOne
	la a4, vetorMSGTwo
	mv a5, a3     	# ponteiro atual de escrita

loop:
	li t6, 55
	bge t0, t6, end   # se t0 >= 55, termina

	lbu t3, 0(a2)   
	andi t3, t3, 1    
	slli t4, t4, 1    
	or t4, t4, t3	 

	addi t2, t2, 1   
	addi a2, a2, 1    

	li t6, 8
	bne t2, t6, loop  # se não acumulou 8 bits, continua loop

	# chegou em 8 bits → grava o byte completo
	sb t4, 0(a5) 	 
	addi a5, a5, 1    
	li t4, 0    	 
	li t2, 0     	 
	addi t0, t0, 1   

	li t6, 31
	beq t0, t6, troca_vetor # se completou vetorMSGOne (31 bytes), troca

	j loop

troca_vetor:
	mv a5, a4     	# muda ponteiro de escrita para vetorMSGTwo
	j loop

end:
	ret


read:
	la a0, input_file	# address for the file path
	li a1, 0         	# flags (0: rdonly, 1: wronly, 2: rdwr)
	li a2, 0         	# mode
	li a7, 1024      	# syscall open
	ecall
    
	la a1, input
	li a2, 4109
	li a7, 63
	ecall
	ret


write:
	li a0, 1        	# file descriptor = 1 (stdout)
	la a1, vetorMSGTwo   	# buffer
	li a2, 24        	# size - Writes 4 bytes.
	li a7, 64       	# syscall write (64)
	ecall
	ret


#Modqpufq zae eqge eaztae
