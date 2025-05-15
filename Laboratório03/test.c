#include <stdio.h>

int main() {
    int soma = 1633771873;  // Valor de exemplo
    char strs[12];          // Buffer para armazenar os dígitos convertidos
    int m = 0;

    while (soma > 0) {
        strs[m] = (soma % 10) + 48;  // Converte o dígito para caractere
        soma = soma / 10;  // Divisão inteira
        m++;
        printf("%c ", strs[m-1]);
    }
    printf("%d aaaaaaaa", soma);

    return 0;
}
