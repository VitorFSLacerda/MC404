.globl _start

_start:
  li x11, 21          # carrega o valor 21 no registrador x11
  li x12, 21          # carrega o valor 21 no registrador x12
  add x10, x11, x12   # soma o conteúdo dos registradores x11 e x12 e 
                      # grava o resultado no registrador x10
  li a7, 93           # carrega o valor 93 no registrador a7
  ecall               # gera uma interrupção por software