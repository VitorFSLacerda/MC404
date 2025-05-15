.globl _start

_start:
  li a0, 231524 # ->000000000000001110001000011001
  li a1, 0    # 000000000000000000000000000001
  li a2, 0
  li a3, -1
loop:
  andi t0, a0, 1          # t0 = 00000000000000000000000000000000001
  add  a2, a2, t0         # a2 = a2 + t0 = 1
  xor  a1, a1, t0         # a1 = a1 xor t0 = 1
  addi a3, a3, 2          # a3 = a3 + 2 = -1 + 2 = 1
  srli a0, a0, 1          # 1001 -> 010 == 000000000000000111000100001100100
  bnez a0, loop

end:
  la a0, result
  sw a2, 4(a0)
  li a0, 0
  li a7, 93
  ecall

result:
  .word 0