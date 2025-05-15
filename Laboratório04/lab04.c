#define STDIN_FD  0
#define STDOUT_FD 1


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


int read(int __fd, void *__buf, int __n)
{
    int ret_val;
    __asm__ __volatile__(
        "mv a0, %1           # file descriptor\n"
        "mv a1, %2           # buffer \n"
        "mv a2, %3           # size \n"
        "li a7, 63           # syscall read (63) \n"
        "ecall               # invoke syscall \n"
        "mv %0, a0           # move return value to ret_val\n"
        : "=r"(ret_val)  // Output list
        : "r"(__fd), "r"(__buf), "r"(__n)    // Input list
        : "a0", "a1", "a2", "a7"
    );
    return ret_val;
}


void hex_code(int val){
    char hex[11];
    unsigned int uval = (unsigned int) val, aux;

    hex[0] = '0';
    hex[1] = 'x';
    hex[10] = '\n';

    for (int i = 9; i > 1; i--){
        aux = uval % 16;
        if (aux >= 10)
            hex[i] = aux - 10 + 'A';
        else
            hex[i] = aux + '0';
        uval = uval / 16;
    }
    write(STDOUT_FD, hex, 11);
}


int converte(char *str) {
    int sign = (str[0] == '-') ? -1 : 1;
    int num = 0;
    for (int i = 1; i < 5; i++) {
        num = num * 10 + (str[i] - '0');
    }
    return sign * num;
}


void pack(int input, int start_bit, int *val) {

    int mask = (1 << 8) - 1; 
    *val |= ((input & mask) << start_bit);
}


void inpack(int input, int start_bit, int *val) {

    unsigned int mask =  4278190080;
    *val |= (input & mask) >> start_bit;
}


void exit(int code) {

  __asm__ __volatile__(
    "mv a0, %0           # return code\n"
    "li a7, 93           # syscall exit (64) \n"
    "ecall"
    :   // Output list
    :"r"(code)    // Input list
    : "a0", "a7"
  );
}

void _start() {
  int ret_code = main();
  exit(ret_code);
}


int main() {
    char str[8][6];
    char lixo;
    int nums[8];
    
    for (int i = 0; i < 8; i++) {
        read(STDIN_FD, str[i], 5);
        str[i][5] = '\0';
        nums[i] = converte(str[i]);
        read(STDIN_FD, &lixo, 1);
        if(lixo == '\n'){
            break;
        }
    }
    
    int n1 = nums[0] & nums[1];
    int n2 = nums[2] | nums[3];
    int n3 = nums[4] ^ nums[5];
    int n4 = ~(nums[6] & nums[7]);
    
    int valor = 0;

    pack(n1, 0, &valor);
    pack(n2, 8, &valor);
    inpack(n3, 0, &valor);
    inpack(n4, 8, &valor);
    hex_code(valor);
    return 0;
}
