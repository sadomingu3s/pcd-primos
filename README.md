# pcd-t1-primos

Trabalho 1 da disciplina de Programação Concorrente e Distribuída (UNIFESP) — estudo experimental sobre desempenho e sustentabilidade de aplicações paralelas em memória compartilhada, usando **contagem de números primos** como aplicação-alvo.

**Pergunta de pesquisa:** como a granularidade decrescente de blocos (schedule `guided`) impacta o consumo de energia comparado a blocos de tamanho fixo (`static`)?

**Hipótese:** o escalonamento dinâmico (`dynamic`/`guided`) é mais eficiente energeticamente do que o estático (`static`), por reduzir o tempo ocioso das threads em cargas de trabalho irregulares.

## Estrutura

```
.
├── src/            # código C (sequencial e versões OpenMP)
├── scripts/        # automação da coleta de experimentos e análise
├── data/           # CSVs de resultados (gerados pela coleta oficial)
├── docs/           # documentação do projeto (ver docs/DOCS.md)
└── artigo/         # artigo final no template SBC
```

## Como compilar

```bash
# versão sequencial
gcc -O2 src/primos_seq.c -o src/seq -lm

# versões OpenMP (uma para cada schedule)
gcc -O2 -fopenmp src/primos_omp_static.c  -o src/static  -lm
gcc -O2 -fopenmp src/primos_omp_dynamic.c -o src/dynamic -lm
gcc -O2 -fopenmp src/primos_omp_guided.c  -o src/guided  -lm
```

## Como rodar

```bash
# validar corretude (deve retornar 78498 primos para N=1.000.000)
./src/seq 1000000

# rodar uma configuração paralela: <N> <threads>
./src/static 20000000 4

# coleta oficial completa (10 repetições x 3 schedules x 4 configs de threads)
bash scripts/run.sh
python3 scripts/analisar.py
```

**Importante:** a coleta oficial (a que vai para o artigo) deve ser rodada em **uma única máquina**, do início ao fim, sem trocar de ambiente — ver `docs/DOCS.md` para o motivo.

## Equipe

| Papel | Responsável |
|---|---|
| Implementação (C/OpenMP) | _preencher_ |
| Protocolo e scripts | _preencher_ |
| Dados e métricas | _preencher_ |
| Energia e referências | _preencher_ |
| Redação do artigo | _preencher_ |

## Status

- [ ] Versão sequencial validada
- [ ] Versões OpenMP (static/dynamic/guided) implementadas
- [ ] Coleta oficial de dados realizada
- [ ] Métricas calculadas (speedup, eficiência, energia estimada)
- [ ] Artigo redigido
