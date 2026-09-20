/*
  primos_omp_dynamic.c

  Contagem de números primos em [2, N] usando OpenMP, com schedule(dynamic).

  Baseado na estrutura de PRIME_OPENMP de John Burkardt
  (https://people.math.sc.edu/Burkardt/c_src/prime_openmp/prime_openmp.c),
  distribuído sob licença MIT/LGPL pelo autor original.

  Adaptações feitas pelo grupo (Trabalho 1 - PCD):
    - Teste de primalidade otimizado com sqrt(n) (o original testava até n-1)
    - N e número de threads recebidos via linha de comando
    - Cláusula schedule(dynamic, chunk) explícita, para o estudo de
      granularidade decrescente vs. fixa
    - Saída em formato CSV (N,threads,primos,tempo) para automação da coleta
*/

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <omp.h>

int eh_primo(long n) {
    if (n < 2) return 0;
    long limite = (long) sqrt((double) n);
    for (long i = 2; i <= limite; i++) {
        if (n % i == 0) return 0;
    }
    return 1;
}

int main(int argc, char *argv[]) {
    if (argc < 3) {
        fprintf(stderr, "Uso: %s <N> <threads> [chunk]\n", argv[0]);
        return 1;
    }

    long N = atol(argv[1]);
    int nthreads = atoi(argv[2]);
    int chunk = (argc >= 4) ? atoi(argv[3]) : 1000;

    long count = 0;

    omp_set_num_threads(nthreads);
    double t0 = omp_get_wtime();

    #pragma omp parallel for reduction(+:count) schedule(dynamic, chunk)
    for (long i = 2; i <= N; i++) {
        if (eh_primo(i)) {
            count++;
        }
    }

    double t1 = omp_get_wtime();

    printf("%ld,%d,%ld,%.6f\n", N, nthreads, count, t1 - t0);

    return 0;
}
