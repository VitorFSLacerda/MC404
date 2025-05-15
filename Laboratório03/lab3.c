int read(int __fd, const void *__buf, int __n){
    int ret_val;
  __asm__ __volatile__(
    "mv a0, %1           # file descriptor\n"
    "mv a1, %2           # buffer \n"
    "mv a2, %3           # size \n"
    "li a7, 63           # syscall write code (63) \n"
    "ecall               # invoke syscall \n"
    "mv %0, a0           # move return value to ret_val\n"
    : "=r"(ret_val)  // Output list
    : "r"(__fd), "r"(__buf), "r"(__n)    // Input list
    : "a0", "a1", "a2", "a7"
  );
  return ret_val;
}

void write(int __fd, const void *__buf, int __n)
{
  __asm__ __volatile__(
    "mv a0, %0           # file descriptor\n"
    "mv a1, %1           # buffer \n"
    "mv a2, %2           # size \n"
    "li a7, 64           # syscall write (64) \n"
    "ecall"
    :   // Output list
    :"r"(__fd), "r"(__buf), "r"(__n)    // Input list
    : "a0", "a1", "a2", "a7"
  );
}

void exit(int code)
{
  __asm__ __volatile__(
    "mv a0, %0           # return code\n"
    "li a7, 93           # syscall exit (64) \n"
    "ecall"
    :   // Output list
    :"r"(code)    // Input list
    : "a0", "a7"
  );
}


#define STDIN_FD  0
#define STDOUT_FD 1


int binToDec(char *numBin){
    int soma = 0;

    for(int i = 1, j = 1; i < 32; i++, j *= 2) {
        if (numBin[32 - i] == '1') {
            soma += j;
        }
    }
    return soma;
}


void binToHex(char *numBin, char *valorHex){ 
    int soma = 0;
    char hexDigits[] = "0123456789ABCDEF";
    char vetor[8][4];

    for(int i = 0; i < 8; i++){
        for(int j = 0; j < 4; j++){
            vetor[i][j] = numBin[i * 4 + j];
        }
        soma = binToDec(vetor[i]);
        valorHex[i+2] = hexDigits[soma];
    }
    valorHex[10] = '\n';
}



void invertStr(char *vetorPrincipal, char *auxVetor, int m, int j){

    while (m > 0) {
        auxVetor[j] = vetorPrincipal[m - 1];  
        j++;
        m--;
    }
    auxVetor[j] = '\n';
    write(STDOUT_FD, auxVetor, j + 1); 

}


int convToStr(char *vetor, int dec){
    int m = 0;

    while (dec > 0) {
        vetor[m] = (dec % 10) + 48;
        dec /= 10;
        m++;
    }
    return m;
}


void copiaStr(char *original, char *copia){

    for(int i = 0; i < 32; i++) {
        if (original[i] == '0'){
            copia[i] = '1';
        }else{
            copia[i] = '0';
        }
    }

}


void complementoDois(char *copia, char *original){
    
    write(STDOUT_FD, copia, 33);
    copiaStr(original, copia);

    copia[32] = '\n';

    write(STDOUT_FD, copia, 33);

    int carry = 1;
    for(int i = 31; i >= 0; i--) {
        if (copia[i] == '0' && carry == 1) {
            copia[i] = '1'; 
            carry = 0;
            break;
        } else if (copia[i] == '1' && carry == 1) {
            copia[i] = '0';
        }
    }
}


void primeiraSaida(char bin[33]){
    char sinal = bin[0];
    char vetor[15];
    int soma = 0;
    char copia[33];
    
    if(sinal == '0'){
        soma = binToDec(bin);
        invertStr(bin, vetor, convToStr(bin, soma), 0);
    
    } else{
        complementoDois(copia, bin);
        soma = binToDec(copia);
        vetor[0] = '-';
        invertStr(bin, vetor, convToStr(bin, soma), 1);
        
    }
}


void terceiraSaida(char bin[33]){
    char sinal = bin[0];
    char hexadecimal[11];
    char complemento[33];
    hexadecimal[0] = '0';
    hexadecimal[1] = 'x';

    if(sinal == '0'){
        binToHex(bin, hexadecimal);
    } else{ 
        complementoDois(complemento, bin);
    

        write(STDOUT_FD, complemento, 33);

        binToHex(complemento, hexadecimal);
    }
    write(STDOUT_FD, hexadecimal, 11);
}



// 11000011101001111100001110100111
// 00111100010110000011110001011000
// 00111100010110000011110001011001

// 00000000100110000011110001011001

// 11000011101001111100001110100111
//c3a7c3a7

int main() {

    char str[33];
    int n = read(STDIN_FD, str, 33);

    //33 \n -> 32 [0] sinal -> 31 relevantes

    primeiraSaida(str);
    //terceiraSaida(str);

    

 
    return 0;
}

void _start() {
  int ret_code = main();
  exit(ret_code);
}