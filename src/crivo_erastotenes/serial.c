/*
  primos_omp_static.c

  Algoritmo Crivo de Erastótenes para contagem de números primos

  Código da solução 2 do trabalho prático 4
  Autor: Fernando Antônio Fernandes Júnior
  (https://homepages.dcc.ufmg.br/~nivio/cursos/pa06/)

  Adaptações feita
*/

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

#define FALSE 0
#define TRUE 1

unsigned long crivo(unsigned long n) {
    unsigned long max_fator = (unsigned long)sqrt((double)n);
    unsigned char *lista = (unsigned char *)malloc((n + 1) * sizeof(unsigned char));
    
    for (unsigned long i = 0; i <= n; i++) {
        lista[i] = FALSE;
    }

    unsigned long fator = 2;
    while (fator <= max_fator) {
        while (lista[fator] == TRUE) {
            fator++;
        }
        unsigned long indice = fator * fator;
        while (indice <= n) {
            lista[indice] = TRUE;
            indice += fator;
        }
        fator++;
    }

    unsigned long contador = 0;
    for (unsigned long i = 2; i <= n; i++) {
        if (lista[i] == FALSE) {
            contador++;
        }
    }

    free(lista);
    return contador;
}

int main(int argc, char *argv[]) {
    unsigned long max = (unsigned long)atol(argv[1]);

    struct timeval TempoInicio, TempoFim;
    gettimeofday(&TempoInicio, NULL);

    unsigned long total_primos = crivo(max);

    gettimeofday(&TempoFim, NULL);
    double TempoEmSegundos = (TempoFim.tv_sec - TempoInicio.tv_sec) +
                             (TempoFim.tv_usec - TempoInicio.tv_usec) / 1000000.0;
    printf("SERIAL\n");
    printf("N: %lu, Quantidade de primos: %lu, Tempo(s): %lf\n", max, total_primos, TempoEmSegundos);
    return 0;
}
