.globl _start

_start:
	jal main

exit:
	li a0, 0
	li a7, 93 # exit
	ecall


main:
	jal read
    
	la t6, input_address  # ponteiro pro início do buffer
    
	###### X de A e C (offset 1)
	addi a0, t6, 1
	jal convert_two_digits
	mv s1, a0          	# s1 = X de A e C

	###### Y de A e B (offset 4)
	addi a0, t6, 4
	jal convert_two_digits
	mv s2, a0          	# s2 = Y de A e B

	###### X de B (offset 9)
	addi a0, t6, 9
	jal convert_two_digits
	mv s3, a0          	# s3 = X de B

	###### Y de C (offset 20)
	addi a0, t6, 20
	jal convert_two_digits
	mv s4, a0          	# s4 = Y de C


    
	jal babylonian_method
	jal int_to_ascii_2_digits  # converte número para string com '\n'

    
	jal write
	j exit


convert_two_digits:
	lb t0, 0(a0)    	# carrega o primeiro caractere (ASCII)
	lb t1, 1(a0)    	# carrega o segundo caractere (ASCII)

	addi t0, t0, -48	# ASCII -> número
	addi t1, t1, -48

	li t2, 10
	mul t0, t0, t2  	# t0 *= 10
	add a0, t0, t1  	# a0 = t0 + t1 → resultado final

	ret


babylonian_method:
#t3 = k
#t2 = 2
#t1 = y
#C - A 	eixo Y
#B - A 	eixo X

	sub t1, s4, s2
	sub t2, s3, s1
	mul t1, t1, t1
	mul t2, t2, t2
	add t1, t1, t2

	li t2, 2
	li t6, 0
    
	div t3, t1, t2 #t3 = k


.loop:
	div t4, t1, t3  # y / k
    
	add t5, t4, t3  # k + (y / k)
    
	div t3, t5, t2  # novo k = (k + y/k)/2
    
    
	addi t6, t6, 1
    
	li s7, 10  # número de iterações (ex: 10)
    
    
	blt t6, s7, .loop

	mv a0, t3   	# retorna resultado em a0
	ret
    

read:
	li a0, 0         	# file descriptor = 0 (stdin)
	la a1, input_address # buffer
	li a2, 24        	# size - Reads 24 bytes.
	li a7, 63        	# syscall read (63)
	ecall
	ret

write:
	li a0, 1        	# file descriptor = 1 (stdout)
	la a1, result   	# buffer
	li a2, 4        	# size - Writes 4 bytes.
	li a7, 64       	# syscall write (64)
	ecall
	ret

.text
int_to_ascii_2_digits:
	li t1, 100

	div t2, a0, t1 # t2 = a0 / 100 → centena


	rem t3, a0, t1    	# t2 = a0 % 100 → Dois da dezena

	li t1, 10

	div t4, t3, t1    	# t3 = t3 / 10 → dezena


	rem t5, t3, t1		# t5 = t3 % 10 → unidade





	addi t2, t2, 48   	# ASCII da dezena
	addi t4, t4, 48   	# ASCII da unidade
	addi t5, t5, 48





	la t6, result

	sb t2, 0(t6)      	# primeiro dígito
	sb t4, 1(t6)      	# segundo dígito
	sb t5, 2(t6)      	# terceiro dígito

	li t5, 10         	# '\n'
	sb t5, 3(t6)

	ret


.bss

input_address: .skip 0x18  # buffer

result: .skip 0x4
