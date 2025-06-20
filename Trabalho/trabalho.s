.data
.align 2
    barN: .byte '\n'                # Caractere de nova linha para uso com puts

# ------------------------------------------------------------------------------
# .bss → Segmento para variáveis não inicializadas (alocação em tempo de execução)
# Cada .skip 6000 reserva 6000 bytes (~1.5 k palavras de 4 bytes)
# ------------------------------------------------------------------------------
.bss
    entrada:           .skip 6000   # Armazena toda entrada lida (3 linhas)
    arquiteturaDaRede: .skip 6000   # Vetor com a arquitetura (ex: 4,10,3)
    conjuntoDeVetores: .skip 6000   # Usado para armazenar temporariamente vetores Ln
    matriz:            .skip 6000   # Vetor de entrada e resultados parciais (modificado a cada camada)
    matrizCopia:       .skip 6000   # Buffer auxiliar usado após multiplicações

    buffer:            .skip 6000   # Buffer para strings (ex: itoa)
    copia:             .skip 6000   # Usado em parse_numeros para extrair string de um número

    tamanho1:          .skip 6000   # Inteiros lidos na arquitetura
    tamanho2:          .skip 6000   # Inteiros lidos em vetores Ln
    tamanho3:          .skip 6000   # Inteiros lidos em vetor de entrada (e depois camada final)

# ------------------------------------------------------------------------------
# Seção de código
# ------------------------------------------------------------------------------
.text
.align 2


# ------------------------------------------------------------------------------
# _start
# Ponto de entrada do programa.
# Fluxo principal:
#   1. Lê toda a entrada (3 linhas) e armazena em `entrada`
#   2. Converte a 1ª linha  -> arquitetura da rede        → vetor `arquiteturaDaRede`
#   3. Converte a 2ª linha  -> dados de entrada (flores)  → vetor `matriz`
#   4. Processa todas as camadas (pesos)  -> `executar_inferencia`
#   5. Calcula argmax da saída final      -> classe prevista
#   6. Converte classe para string e imprime
#   7. Encerra o programa
# ------------------------------------------------------------------------------
_start:

    # ------------------------------------------------------------------
    # 1) Lê as 3 linhas de entrada e armazena em `entrada`
    # ------------------------------------------------------------------
    la  a0, entrada           # a0 ← ponteiro para buffer de entrada
    jal gets                  # lê até encontrar 3 quebras de linha

    # ------------------------------------------------------------------
    # 2) Processa a 1ª linha: arquitetura da rede (ex: "4,10,3")
    #    Salva inteiros em `arquiteturaDaRede` e quantidade em `tamanho1`
    # ------------------------------------------------------------------
    la  a0, entrada           # ponteiro para início da string
    la  a1, arquiteturaDaRede # destino dos inteiros convertidos
    la  a2, tamanho1          # onde gravar quantidade lida
    jal interpretar_numeros   # converte números da 1ª linha

    # ------------------------------------------------------------------
    # 3) Processa a 2ª linha: vetor de entrada (ex: "5,3,1,0")
    #    Usa `contador_fim` para saltar o bloco de pesos e chegar na 2ª linha
    # ------------------------------------------------------------------
    la  a0, entrada           # reinicia ponteiro no início
    jal contador_fim          # avança até depois do bloco de pesos ('}')
    la  a1, matriz            # destino dos 4 inteiros da amostra
    la  a2, tamanho3          # onde gravar quantidade lida
    jal interpretar_numeros   # converte números da 2ª linha

    # ------------------------------------------------------------------
    # 4) Executa a inferência completa (multiplicação + ReLU) camada a camada
    #    A função usa a string em `entrada` para percorrer todos os vetores Ln
    # ------------------------------------------------------------------
    la  a0, entrada           # ponteiro para string com todos os pesos
    jal executar_inferencia   # forward pass

    # ------------------------------------------------------------------
    # 5) Calcula argmax do vetor de saída final (matriz)
    # ------------------------------------------------------------------
    la  a0, matriz            # ponteiro para vetor de saída final
    lw  a1, tamanho3          # a1 ← quantidade de elementos na saída
    jal argmax                # a0 ← índice da maior probabilidade

    # ------------------------------------------------------------------
    # 6) Converte índice (classe) para string e imprime
    # ------------------------------------------------------------------
    la  a1, buffer            # buffer para saída de texto
    li  a2, 10                # base 10
    jal itoa                  # a0 (classe) → string em `buffer`
    jal puts                  # imprime string

    # ------------------------------------------------------------------
    # 7) Encerra o programa
    # ------------------------------------------------------------------
    jal exit



# ---------------------------------------------------------
# argmax
# Entrada:
#   a0 → ponteiro para vetor de inteiros
#   a1 → número de elementos no vetor
# Saída:
#   a0 → índice do maior valor encontrado no vetor
# ---------------------------------------------------------
argmax:
    addi sp, sp, -16
    sw ra, 12(sp)         # Salva endereço de retorno
    sw a1, 8(sp)          # Salva o número de elementos (n)

    mv t0, a0             # t0 ← ponteiro atual para o vetor
    li t1, 0              # t1 ← índice atual
    li t2, 0              # t2 ← índice do maior valor até agora
    lw t3, 0(t0)          # t3 ← maior valor até agora (inicializa com o primeiro)

    lw t5, 8(sp)          # t5 ← contador de elementos restantes

    # Loop que percorre o vetor comparando os valores
    loop_argmax:
        addi t5, t5, -1       # Decrementa contador
        beqz t5, fim_argmax   # Se chegou no fim, sai do loop

        addi t1, t1, 1        # t1 ← índice atual + 1
        addi t0, t0, 4        # Avança ponteiro para o próximo inteiro
        lw t4, 0(t0)          # t4 ← próximo valor do vetor

        bgt t4, t3, atualiza  # Se o valor atual é maior que o máximo anterior, atualiza
        j loop_argmax         # Caso contrário, continua o loop

    # Atualiza o maior valor e seu índice
    atualiza:
        mv t3, t4             # t3 ← novo maior valor
        mv t2, t1             # t2 ← novo índice correspondente ao maior valor
        j loop_argmax         # Continua o loop

    # Fim: retorna o índice do maior valor
    fim_argmax:
        mv a0, t2             # a0 ← índice do maior valor
        lw ra, 12(sp)         # Restaura endereço de retorno
        addi sp, sp, 16       # Libera espaço na pilha
        ret


# -------------------------------------------------------------------
# executar_inferencia
# Executa a inferência da rede camada por camada (Ln por Ln)
# Entrada:
#   a0 → ponteiro para o início do próximo bloco Ln na string de entrada
# Saída:
#   nenhuma (efeitos colaterais: atualiza o vetor `matriz` com saída final)
# -------------------------------------------------------------------
executar_inferencia:
    addi sp, sp, -16
    sw ra, 12(sp)            # Salva o endereço de retorno
    sw a0, 8(sp)             # Salva o ponteiro da string de entrada

    loop_executar_inferencia:
        lw a0, 8(sp)             # Recupera o ponteiro atual da string de entrada
        jal scaneamento          # Avança até o início do próximo vetor de pesos ("Ln")

        lb t0, 0(a0)             # Carrega o próximo caractere da string
        li t1, 125               # ASCII de '}'
        beq t0, t1, fim_executar_inferencia
                                # Se encontrar '}', terminou todos os blocos Ln

        # Carrega o próximo vetor de pesos (Ln) e armazena em conjuntoDeVetores
        la a1, conjuntoDeVetores
        la a2, tamanho2
        jal interpretar_numeros  # Converte o próximo vetor de pesos e atualiza a0

        sw a0, 8(sp)             # Atualiza ponteiro da string para próxima iteração

        # Multiplica o vetor de pesos pela entrada atual (matriz)
        la a0, conjuntoDeVetores # pesos Ln
        la a1, matriz            # entrada atual
        la a2, tamanho2          # tamanho dos pesos
        la a3, tamanho3          # tamanho da entrada atual
        jal multiplica_matriz    # resultado será colocado em matrizCopia

        # Atualiza matriz com o novo vetor resultante da multiplicação
        jal troca

        # Aplica a função de ativação ReLU ao vetor de saída
        la a0, matriz
        la a1, tamanho3
        jal relu

        # Recomeça para o próximo bloco Ln
        j loop_executar_inferencia

    fim_executar_inferencia:
        lw ra, 12(sp)            # Restaura o endereço de retorno
        addi sp, sp, 16          # Libera espaço da pilha
        ret


# ------------------------------------------------------------------------
# relu
# Aplica a função de ativação ReLU ao vetor fornecido.
# ReLU(x) = max(0, x)
#
# Entrada:
#   a0 → ponteiro para vetor de inteiros
#   a1 → ponteiro para a quantidade de elementos do vetor
# Saída:
#   vetor em a0 é modificado in-place (valores negativos se tornam 0)
# ------------------------------------------------------------------------

relu:
    addi sp, sp, -16
    sw ra, 12(sp)          # Salva o endereço de retorno
    sw a0, 8(sp)           # Salva ponteiro do vetor original
    sw a1, 4(sp)           # Salva ponteiro do tamanho do vetor

    lw t2, 0(a1)           # t2 ← número de elementos no vetor
    li t3, 0               # t3 ← índice atual (contador)

    loop_relu:
        beq t3, t2, fim_relu   # Se t3 == t2, terminou o processamento do vetor

        lw t1, 0(a0)           # t1 ← valor atual do vetor

        # Extensão de sinal para garantir que valores negativos em 8 bits
        # sejam corretamente interpretados como negativos em 32 bits
        andi t1, t1, 0xFF      # isola os 8 bits inferiores
        slli t1, t1, 24        # move os bits para a posição mais alta
        srai t1, t1, 24        # aplica extensão de sinal

        bltz t1, zera          # Se t1 < 0, pula para zera
        j escreve              # Caso contrário, escreve o valor como está

    zera:
        li t1, 0               # zera o valor se for negativo

    escreve:
        sw t1, 0(a0)           # escreve t1 (ReLU aplicado) na posição atual
        addi a0, a0, 4         # avança ponteiro do vetor para próximo inteiro
        addi t3, t3, 1         # incrementa o índice
        j loop_relu            # repete para o próximo valor

    fim_relu:
        lw ra, 12(sp)          # restaura o endereço de retorno
        addi sp, sp, 16        # libera espaço na pilha
        ret


# ------------------------------------------------------------------------
# multiplica_matriz
# Realiza a multiplicação entre cada vetor de entrada (Ln) e a matriz de pesos.
#
# Entrada:
#   a0 → conjuntoDeVetores: vetor contendo todos os Ln's concatenados
#   a1 → matriz: vetor de pesos
#   a2 → tamanho2: ponteiro para inteiro com tamanho total de conjuntoDeVetores
#   a3 → tamanho3: ponteiro para inteiro com tamanho de cada Ln (e da matriz)
#
# Saída:
#   Escreve os resultados da multiplicação na matrizCopia
#   a0 ← quantidade de multiplicações (número de vetores Ln)
# ------------------------------------------------------------------------

multiplica_matriz:
    addi sp, sp, -32
    sw ra, 28(sp)        # Salva endereço de retorno
    sw a0, 24(sp)        # Salva ponteiro conjuntoDeVetores
    sw a1, 20(sp)        # Salva ponteiro matriz
    sw a2, 16(sp)        # Salva ponteiro tamanho2
    sw a3, 12(sp)        # Salva ponteiro tamanho3

    la t4, matrizCopia   # t4 → início do vetor resultado (matrizCopia)

    lw t0, 0(a2)         # t0 ← total de elementos no conjuntoDeVetores
    lw t1, 0(a3)         # t1 ← tamanho de cada vetor Ln
    beqz t1, fim_mul     # Se tamanho for 0, não há o que multiplicar

    div t2, t0, t1       # t2 ← quantidade de vetores Ln
    sw t2, 8(sp)         # Salva contador de vetores restantes
    sw t2, 4(sp)         # Também salva o total (para retornar depois)

    # Restaura ponteiros base dos vetores
    lw a0, 24(sp)        # conjuntoDeVetores
    lw a1, 20(sp)        # matriz

    loop_multiplica_matriz:
        # Para cada Ln, reinicia os valores
        lw t1, 0(a3)         # t1 ← tamanho do vetor Ln (n)
        li t3, 0             # t3 ← acumulador do produto escalar
        li t5, 0             # t5 ← produto parcial

    loop_produto:
        beqz t1, coloca_no_vetor  # Se percorreu o vetor inteiro, salva resultado

        lw t0, 0(a0)         # t0 ← elemento atual do Ln
        lw t6, 0(a1)         # t6 ← elemento correspondente da matriz

        mul t5, t0, t6       # t5 ← multiplicação t0 * t6
        add t3, t3, t5       # t3 ← acumula valor do produto escalar

        addi a0, a0, 4       # Avança ponteiro do conjuntoDeVetores
        addi a1, a1, 4       # Avança ponteiro da matriz
        addi t1, t1, -1      # Decrementa contador de elementos restantes
        j loop_produto

    coloca_no_vetor:
        sw t3, 0(t4)         # Armazena resultado (produto escalar) em matrizCopia
        addi t4, t4, 4       # Avança ponteiro de escrita da matrizCopia

        lw t2, 8(sp)         # Carrega contador de vetores restantes
        addi t2, t2, -1      # Decrementa
        sw t2, 8(sp)         # Atualiza na pilha
        beqz t2, fim_mul     # Se não há mais vetores, fim

        lw a1, 20(sp)        # Restaura ponteiro da matriz (fixa para cada vetor Ln)
        j loop_multiplica_matriz

    fim_mul:
        lw ra, 28(sp)        # Recupera endereço de retorno
        lw a0, 4(sp)         # Retorna quantidade de produtos realizados
        addi sp, sp, 32      # Libera pilha
        ret


# ------------------------------------------------------------------------------
# troca
# Copia os resultados da matrizCopia para a matriz principal (matriz),
# e atualiza o tamanho da matriz (tamanho3) com a nova quantidade de elementos.
#
# Entrada:
#   a0 → ponteiro para inteiro com o novo tamanho da matriz (após multiplicação)
#
# Efeito:
#   Sobrescreve a matriz original com os valores de matrizCopia
#   Atualiza o valor em tamanho3
# ------------------------------------------------------------------------------
troca:
    addi sp, sp, -16
    sw ra, 12(sp)           # Salva endereço de retorno
    sw a0, 8(sp)            # Salva ponteiro para o novo tamanho

    lw t0, 8(sp)            # t0 ← novo tamanho (número de inteiros a copiar)

    la a1, matriz           # a1 ← destino (matriz original)
    la a2, matrizCopia      # a2 ← origem (matrizCopia)
    la a3, tamanho3         # a3 ← local onde armazenar o novo tamanho
    sw t0, 0(a3)            # Atualiza o valor de tamanho3 com o novo tamanho

    troca_loop:
        beqz t0, troca_fim      # Se t0 == 0, terminou a cópia

        lw t1, 0(a2)            # t1 ← próximo valor da matrizCopia
        sw t1, 0(a1)            # Armazena t1 na matriz original

        addi a1, a1, 4          # Avança ponteiro do destino (matriz)
        addi a2, a2, 4          # Avança ponteiro da origem (matrizCopia)
        addi t0, t0, -1         # Decrementa contador
        j troca_loop            # Continua copiando

    troca_fim:
        lw ra, 12(sp)           # Recupera endereço de retorno
        addi sp, sp, 16         # Libera pilha
        ret


# ------------------------------------------------------------------------------
# interpretar_numeros
# Lê uma string contendo números inteiros representados em texto (como "3, 5, 7")
# e converte esses números para inteiros, armazenando-os sequencialmente em um vetor.
#
# Entradas:
#   a0 → ponteiro para a string original com os dados (ex: "[3, 5, 7]")
#   a1 → ponteiro para o vetor onde os inteiros convertidos serão armazenados
#   a2 → ponteiro onde será salvo o número total de inteiros lidos
#
# Saídas:
#   Os inteiros convertidos são armazenados no vetor apontado por a1.
#   *(a2) recebe a quantidade de inteiros lidos e armazenados.
# ------------------------------------------------------------------------------
interpretar_numeros:
    addi sp, sp, -32
    sw ra, 12(sp)         # Salva endereço de retorno
    sw a0, 8(sp)          # Salva ponteiro para a string de entrada
    sw a1, 4(sp)          # Salva ponteiro para o vetor de saída

    li s1, 0              # Inicializa contador de inteiros lidos

    loop_interpretar_numeros:
        lw a0, 8(sp)          # Recupera ponteiro atual da string
        lb t0, (a0)           # Carrega caractere atual

        # Verifica delimitadores de fim
        li t1, 123            # '{'
        beq t0, t1, fim_interpretar_numeros
        li t1, 125            # '}'
        beq t0, t1, fim_interpretar_numeros
        li t1, 93             # ']'
        beq t0, t1, fim_interpretar_numeros
        li t1, 91             # '['
        beq t0, t1, pula_proximo_vetor_dentro_de_ln
        beqz t0, fim_interpretar_numeros  # fim da string

        # Ignora espaços
        li t1, 32             # ' '
        beq t0, t1, pula_espaco_interpretar_numeros

        # Extrai próximo número em formato string
        jal parse_numeros
        sw a0, 8(sp)          # Atualiza ponteiro da string

        # Pega a string do número em 'copia'
        la a0, copia
        lb t0, 0(a0)
        beqz t0, loop_interpretar_numeros  # se string vazia, continua o loop

        jal atoi              # Converte string para inteiro
        lw a1, 4(sp)          # Recupera ponteiro para vetor de inteiros
        sw a0, 0(a1)          # Armazena inteiro convertido
        addi a1, a1, 4        # Avança ponteiro para próxima posição do vetor
        sw a1, 4(sp)          # Salva novo ponteiro atualizado
        addi s1, s1, 1        # Incrementa contador de inteiros
        j loop_interpretar_numeros

    # Pula espaços entre números
    pula_espaco_interpretar_numeros:
        addi a0, a0, 1
        sw a0, 8(sp)
        j loop_interpretar_numeros

    # Ignora vetor interno (ex: "[...]") e continua leitura
    pula_proximo_vetor_dentro_de_ln:
        addi a0, a0, 1
        sw a0, 8(sp)
        j loop_interpretar_numeros

    # Finaliza e retorna
    fim_interpretar_numeros:
        sw s1, 0(a2)          # Armazena quantidade de inteiros lidos
        lw ra, 12(sp)
        addi sp, sp, 32
        ret


# ------------------------------------------------------------------------------
# parse_numeros
# Lê caracteres da string original (a0) até encontrar um separador (vírgula, '\n', ']', etc.)
# e armazena o número (em formato de texto) no buffer `copia`.
#
# Entrada:
#   a0 → ponteiro para string contendo um número em texto (ex: "123, ...")
#
# Saídas:
#   a0 → ponteiro atualizado para a próxima posição na string original
#   copia → contém a string do número isolado (ex: "123\0")
# ------------------------------------------------------------------------------
parse_numeros:
    addi sp, sp, -16
    sw ra, 12(sp)          # Salva endereço de retorno

    mv t0, a0              # t0 ← ponteiro atual da string
    la a4, copia           # a4 ← ponteiro para o buffer de saída (copia)

    loop_parse:
        lb t3, 0(t0)           # t3 ← caractere atual da string

        # Verifica separadores válidos para fim do número
        li t4, 44              # ','
        li t5, 10              # '\n'
        li t6, 93              # ']'
        beq t3, t4, fim        # Se encontrar ',', fim do número
        beq t3, t5, fim        # Se encontrar '\n', fim do número
        beq t3, t6, fim        # Se encontrar ']', fim do número

        li t6, 32              # espaço
        beq t3, t6, ignora_espaco_parse

        li t6, 91              # '['
        beq t3, t6, fim

        beqz t3, fim           # fim da string ('\0'), segurança extra

        # Se não for separador, copia caractere para o buffer
        sb t3, 0(a4)           # armazena caractere em copia
        addi a4, a4, 1         # avança buffer de destino
        addi t0, t0, 1         # avança na string original
        j loop_parse

    ignora_espaco_parse:
        addi t0, t0, 1         # pula espaço
        j loop_parse

    fim:
        sb zero, 0(a4)         # adiciona terminador nulo na string copia
        addi t0, t0, 1         # avança ponteiro para depois do separador
        mv a0, t0              # atualiza a0 com novo ponteiro da string original

        lw ra, 12(sp)
        addi sp, sp, 16
        ret


# ------------------------------------------------------------------------------
# scaneamento
# Avança o ponteiro `a0` até encontrar o próximo vetor "Ln" na string.
# O início de um vetor Ln é identificado pela letra 'l' (de "Ln") na entrada.
# 
# Entrada:
#   a0 → ponteiro para a string original
#
# Saída:
#   a0 → atualizado para apontar para o número imediatamente após "ln": ex: 'l0: [1, 2, 3]'
#         → o ponteiro vai parar no '1' (posição após o 'l0: [')
#
# Observação:
#   Se encontrar '}' antes de um 'l', retorna diretamente (fim da execução)
# ------------------------------------------------------------------------------
scaneamento:
    addi sp, sp, -16         # Cria espaço na pilha
    sw ra, 12(sp)            # Salva endereço de retorno

    scan:
        lb t1, 0(a0)             # t1 ← caractere atual da string

        li t2, 108               # ASCII de 'l'
        beq t1, t2, next         # Se for 'l', salta para next (achou novo bloco Ln)

        li t2, 125               # ASCII de '}'
        beq t1, t2, finished     # Se for '}', fim dos vetores (encerra o processamento)

        addi a0, a0, 1           # Avança para próximo caractere
        j scan                   # Repete até encontrar 'l' ou '}'

    next:
        addi a0, a0, 7           # Avança 7 posições após o 'l' (pula "l0: [")
                                # OBS: depende da estrutura da entrada estar sempre nesse formato
        lw ra, 12(sp)
        addi sp, sp, 16
        ret                      # Retorna com a0 posicionado no início dos números

    finished:
        lw ra, 12(sp)            # Recupera endereço de retorno
        addi sp, sp, 16          # Libera pilha
        ret                      # Retorna com a0 intacto (apontando para '}')


# ------------------------------------------------------------------------------
# contador_fim
# Avança o ponteiro da string até encontrar o caractere '}' (fim de um bloco).
#
# Entrada:
#   a0 → ponteiro para a string
#
# Saída:
#   a0 → atualizado para duas posições após o caractere '}' (pula '} e \n', por exemplo)
#
# Uso típico:
#   Utilizado após processar um vetor Ln, para posicionar `a0` corretamente no início
#   do próximo bloco ou após todos os blocos.
# ------------------------------------------------------------------------------
contador_fim:
    addi sp, sp, -16
    sw ra, 12(sp)        # Salva endereço de retorno
    sw a0, 8(sp)         # Salva ponteiro original da string (para referência, se necessário)

    loop_contador:
        lb t0, 0(a0)         # t0 ← caractere atual da string

        li t1, 125           # ASCII de '}'
        beq t0, t1, fim_contador  # Se encontrar '}', termina o loop

        addi a0, a0, 1       # Avança para o próximo caractere
        j loop_contador      # Continua a varredura

    fim_contador:
        addi a0, a0, 2       # Avança mais 2 posições após '}' (ex: para pular '\n' ou ',')
        lw ra, 12(sp)        # Recupera endereço de retorno
        addi sp, sp, 16      # Libera pilha
        ret                  # Retorna com a0 apontando para o início da próxima seção


# ------------------------------------------------------------------------------
# itoa
# Converte um número inteiro para string (base 10 ou 16).
#
# Assinatura:
#   char* itoa(int value, char* buffer, int base)
#
# Entradas:
#   a0 → valor inteiro a ser convertido
#   a1 → buffer onde será armazenada a string
#   a2 → base da conversão (10 ou 16)
#
# Saída:
#   a0 → ponteiro para o início da string resultante (mesmo que a1)
#
# Observação:
#   A função inverte a string no final, pois os dígitos são armazenados de trás pra frente.
# ------------------------------------------------------------------------------
itoa:
    addi sp, sp, -32
    sw ra, 0(sp)         # Salva endereço de retorno
    sw a1, 4(sp)         # Salva ponteiro original do buffer
    sw a2, 8(sp)         # Salva a base (10 ou 16)

    mv t0, a0            # t0 ← valor a ser convertido
    li t6, 0             # t6 ← flag de sinal negativo (0 = positivo)

    bltz t0, nega        # Se valor < 0, pula para nega

    continua:
        mv s0, a2            # s0 ← base
        mv t1, a1            # t1 ← ponteiro de escrita no buffer

    itoa_loop:
        rem t3, t0, s0       # t3 ← dígito atual = t0 % base
        li t2, 10
        bge t3, t2, converte_hex  # Se t3 ≥ 10, converte para letra (hexadecimal)

        addi t3, t3, 48      # Caso contrário: t3 = t3 + '0' (48) → caractere numérico
        j salva_digito

    converte_hex:
        addi t3, t3, 55      # t3 = t3 + 'A' - 10 → caractere alfabético para hex

    salva_digito:
        sb t3, 0(t1)         # Armazena caractere no buffer
        addi t1, t1, 1       # Avança ponteiro do buffer
        div t0, t0, s0       # t0 = t0 / base
        bnez t0, itoa_loop   # Se ainda restam dígitos, continua

        beqz t6, itoa_termina  # Se o número era positivo, vai direto para terminar

        li t4, 45            # ASCII de '-'
        sb t4, 0(t1)         # Adiciona sinal negativo
        addi t1, t1, 1

    itoa_termina:
        sb zero, 0(t1)       # Finaliza string com '\0'

        # Inverte string (pois foi construída de trás pra frente)
        lw a1, 4(sp)         # Início do buffer
        mv t2, a1            # t2 ← início
        add t3, t1, zero     # t3 ← fim
        addi t3, t3, -1      # Ajusta para último caractere válido

    inverte_loop:
        bge t2, t3, fim_inverte  # Se ponteiros se cruzam, terminou

        lb t4, 0(t2)         # t4 ← caractere na esquerda
        lb t5, 0(t3)         # t5 ← caractere na direita
        sb t5, 0(t2)         # Troca
        sb t4, 0(t3)
        addi t2, t2, 1       # Avança esquerda →
        addi t3, t3, -1      # Avança direita ←
        j inverte_loop

    fim_inverte:
        lw ra, 0(sp)         # Recupera endereço de retorno
        addi sp, sp, 32      # Libera pilha
        mv a0, a1            # Retorna ponteiro para início do buffer
        ret

    nega:
        li t6, -1            # Define flag de negativo
        mul t0, t0, t6       # Torna valor positivo
        j continua           # Continua processo normalmente


# ------------------------------------------------------------------------------
# atoi
# Converte uma string contendo um número decimal em um valor inteiro.
#
# Assinatura:
#   int atoi(char* str)
#
# Entrada:
#   a0 → ponteiro para string contendo o número (ex: "-123", " 45", "007")
#
# Saída:
#   a0 → valor inteiro correspondente
#
# Observações:
#   - Ignora espaços em branco iniciais
#   - Suporta sinal negativo ('-')
#   - Para de ler quando encontra caractere não numérico
# ------------------------------------------------------------------------------
atoi:
    addi sp, sp, -16
    sw ra, 0(sp)         # Salva endereço de retorno
    sw a0, 4(sp)         # Salva ponteiro original (opcional)

    li t0, 1             # t0 ← sinal (1 = positivo, -1 = negativo)
    li t4, 0             # t4 ← acumulador do número

    loop3:
        lb t1, 0(a0)         # t1 ← caractere atual

        li t2, 32            # ASCII do espaço
        beq t1, t2, skipEspaco  # Ignora espaços

        li t2, 45            # ASCII de '-'
        beq t1, t2, negativo  # Trata sinal negativo

        j convertInt         # Caso contrário, começa a conversão

    skipEspaco:
        addi a0, a0, 1       # Avança para o próximo caractere
        j loop3

    negativo:
        li t0, -1            # Define sinal negativo
        addi a0, a0, 1       # Avança para o número
        j convertInt

    convertInt:
        lb t1, 0(a0)         # Lê caractere atual

        beqz t1, terminou    # Fim de string

        li t2, 10            # Base 10
        li t3, 48            # ASCII de '0'
        blt t1, t3, terminou # Se < '0', não é dígito → termina
        li t5, 57            # ASCII de '9'
        bgt t1, t5, terminou # Se > '9', não é dígito → termina

        mul t4, t4, t2       # t4 ← t4 * 10
        sub t1, t1, t3       # Converte caractere para número (ex: '5' → 5)
        add t4, t4, t1       # Soma o dígito ao acumulador

        addi a0, a0, 1       # Avança para o próximo caractere
        j convertInt

    terminou:
        mul t4, t4, t0       # Aplica o sinal
        mv a0, t4            # Resultado final em a0
        lw ra, 0(sp)         # Restaura endereço de retorno
        addi sp, sp, 16      # Libera pilha
        ret


# ------------------------------------------------------------------------------
# gets
# Lê da entrada padrão (stdin) até encontrar 3 quebras de linha ('\n'),
# salvando os caracteres no buffer fornecido.
#
# Assinatura:
#   void gets(char* buffer)
#
# Entrada:
#   a0 → ponteiro para buffer onde será salva a string lida
#
# Saída:
#   a0 → retorna o mesmo ponteiro original (endereço de início do buffer)
#   buffer → contém os caracteres lidos com terminador nulo '\0'
#
# Observações:
#   - Utiliza syscall 63 para leitura (read)
#   - Lê um caractere por vez
#   - Insere '\0' ao final para formar string C válida
# ------------------------------------------------------------------------------
gets:
    addi sp, sp, -16
    sw ra, 12(sp)         # Salva endereço de retorno
    sw a0, 8(sp)          # Salva ponteiro original
    mv a1, a0             # a1 ← onde salvará o próximo caractere
    li t1, 0              # t1 ← contador de '\n'

    loop2:
        # Realiza chamada de sistema: read(0, a1, 1)
        li a0, 0              # stdin (descritor 0)
        mv a1, a1             # ponteiro para onde salvar caractere
        li a2, 1              # tamanho da leitura (1 byte)
        li a7, 63             # syscall 63 = read
        ecall

        lb t5, 0(a1)          # lê o caractere salvo
        li t0, 10             # '\n' == 10
        beq t5, t0, conta_nl  # se for '\n', incrementa contador
        addi a1, a1, 1        # senão, avança buffer
        j loop2

    conta_nl:
        addi t1, t1, 1        # t1++ (conta nova linha)
        li t2, 3
        beq t1, t2, fim2      # se já encontrou 3 novas linhas, termina
        addi a1, a1, 1        # senão, avança buffer e continua lendo
        j loop2

    fim2:
        sb zero, 0(a1)        # adiciona terminador nulo '\0'
        lw ra, 12(sp)         # restaura endereço de retorno
        lw a0, 8(sp)          # restaura ponteiro original para retornar
        addi sp, sp, 16       # libera espaço da pilha
        ret


# ------------------------------------------------------------------------------
# puts
# Imprime uma string na saída padrão (stdout), caractere por caractere.
#
# Assinatura:
#   void puts(char* s)
#
# Entrada:
#   a0 → ponteiro para string terminada em '\0'
#
# Comportamento:
#   - Imprime os caracteres até encontrar '\0' ou '\n'
#   - Adiciona uma quebra de linha ao final, mesmo se a string não tiver '\n'
#
# Obs: usa syscall 64 (write) para saída padrão
# ------------------------------------------------------------------------------
puts:
    addi sp, sp, -16
    sw ra, 12(sp)         # Salva endereço de retorno
    sw a0, 8(sp)          # Salva ponteiro original da string
    mv t1, a0             # t1 ← ponteiro de leitura da string

    loop1:
        lb t0, 0(t1)          # t0 ← caractere atual da string
        li t3, 10             # ASCII de '\n'
        beq t0, t3, acabou    # Se encontrar '\n', pula para fim
        beqz t0, acabou       # Se encontrar '\0', pula para fim

        # write(1, t1, 1) → imprime caractere
        li a0, 1              # stdout (descritor 1)
        mv a1, t1             # ponteiro para caractere
        li a2, 1              # tamanho: 1 byte
        li a7, 64             # syscall 64 = write
        ecall

        addi t1, t1, 1        # Avança para próximo caractere
        j loop1

    acabou:
        # Escreve um '\n' extra ao final da saída (comportamento padrão de puts)
        li a0, 1              # stdout
        la a1, barN           # ponteiro para '\n' armazenado na .data
        li a2, 1              # 1 byte
        li a7, 64             # syscall 64 = write
        ecall

        lw ra, 12(sp)         # Recupera endereço de retorno
        lw a0, 8(sp)          # Restaura ponteiro original
        addi sp, sp, 16       # Libera pilha
        ret


# ------------------------------------------------------------------------------
# exit
# Encerra a execução do programa com código de saída 0.
#
# Assinatura:
#   void exit()
#
# Comportamento:
#   - Utiliza syscall 93 (exit) no ambiente RISC-V
#   - Retorna código 0 (sucesso)
# ------------------------------------------------------------------------------
exit:
    li a0, 0          # Código de saída (0 = sucesso)
    li a7, 93         # Código da syscall para exit
    ecall             # Chamada do sistema
 