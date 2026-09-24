/*
 * Contagem de numeros primos usando o Crivo de Eratostenes e OpenMP.
 *
 * Nesta versao, a marcacao dos multiplos usa schedule(guided,
 * chunk_size_min): os primeiros blocos sao maiores e diminuem ao longo da
 * execucao, respeitando o tamanho minimo informado.
 */

#include <math.h>   
#include <stdio.h>  
#include <stdlib.h> 
#include <omp.h>    

// Valores usados para indicar se um numero foi marcado como composto.
#define FALSE 0
#define TRUE 1

/*
 * Conta quantos numeros primos existem no intervalo [2, n].
 *
 * chunk_size_min e o tamanho minimo dos blocos do escalonamento guiado.
 * O OpenMP comeca usando blocos maiores e reduz seu tamanho conforme as
 * iteracoes restantes diminuem.
 */
unsigned long crivo_omp_guided(unsigned long n, int chunk_size_min) {
    // Nenhum composto menor ou igual a n precisa ser marcado por um fator
    // maior que a raiz quadrada de n.
    unsigned long max_fator = (unsigned long)sqrt((double)n);

    // lista[i] vale TRUE quando i foi identificado como numero composto.
    unsigned char *lista = (unsigned char *)malloc((n + 1) * sizeof(unsigned char));
    if (lista == NULL) exit(1); // Encerra se nao houver memoria suficiente.

    // Inicialmente, nenhum numero esta marcado como composto.
    for (unsigned long i = 0; i <= n; i++) lista[i] = FALSE;

    unsigned long fator = 2;

    // Processa os possiveis fatores ate sqrt(n).
    while (fator <= max_fator) {
        // Se o fator ja foi marcado, ele e composto e pode ser ignorado.
        while (lista[fator] == TRUE) fator++;

        // Os multiplos menores que fator * fator ja foram marcados por fatores
        // anteriores. Por isso, a marcacao pode comecar neste ponto.
        unsigned long indice_inicial = fator * fator;

        // O escalonamento guiado usa blocos grandes no inicio e reduz seu
        // tamanho progressivamente, ate atingir chunk_size_min.
        #pragma omp parallel for schedule(guided, chunk_size_min)
        for (unsigned long i = indice_inicial; i <= n; i += fator) {
            lista[i] = TRUE;
        }

        fator++;
    }

    unsigned long contador = 0;

    // Conta, em paralelo, os numeros que nao foram marcados como compostos.
    // A reducao cria um contador privado por thread e soma os resultados ao fim.
    #pragma omp parallel for reduction(+:contador)
    for (unsigned long i = 2; i <= n; i++) {
        if (lista[i] == FALSE) contador++;
    }

    free(lista); // Libera a memoria reservada para o crivo.
    return contador;
}

int main(int argc, char *argv[]) {
    // O programa espera: ./omp_guided <N> <tamanho_minimo_do_chunk>.
    if (argc < 3) return 1;

    unsigned long max = (unsigned long)atol(argv[1]);
    int chunk_size_min = atoi(argv[2]);

    // Inicia a medicao usando o relogio de alta precisao do OpenMP.
    double start_time = omp_get_wtime();
    unsigned long total_primos = crivo_omp_guided(max, chunk_size_min);
    double end_time = omp_get_wtime();

    printf("PARALELO - GUIDED\n");
    printf("N: %lu \t Quantidade de primos: %lu \t Tempo(s): %lf\n", max, total_primos, end_time - start_time);
    return 0;
}
