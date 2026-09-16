#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int eh_primo(long n) {
    if (n < 2) return 0;
    for (long i = 2; i <= sqrt((double)n); i++)
        if (n % i == 0) return 0;
    return 1;
}

int main(int argc, char** argv) {
    long N = atol(argv[1]);
    long count = 0;
    for (long i = 2; i <= N; i++)
        if (eh_primo(i)) count++;
    printf("N=%ld primos=%ld\n", N, count);
    return 0;
}