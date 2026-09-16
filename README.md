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
```

**Importante:** a coleta oficial (a que vai para o artigo) deve ser rodada em **uma única máquina**, do início ao fim, sem trocar de ambiente — ver `docs/DOCS.md` para o motivo.
iciência, energia estimada)

# Documentação do Projeto

## 1. Contexto

Trabalho da disciplina Programação Concorrente e Distribuída, primeira etapa (memória compartilhada). Aplicação escolhida: contagem de números primos por divisão por tentativa, em um intervalo `[2, N]`.

## 2. Pergunta de pesquisa e hipótese

**Pergunta:** Como a estratégia de granularidade decrescente de blocos (maiores no início, menores no fim) impacta o consumo de energia em comparação com blocos de tamanho fixo?

**Hipótese:** o escalonamento dinâmico dos blocos é mais eficiente energeticamente do que o estático.

**Justificativa teórica:** o teste de primalidade por divisão por tentativa custa O(√n) por número, então o custo por iteração cresce ao longo do intervalo — a carga é irregular. Com `schedule(static)`, blocos são definidos antes da execução, sem considerar esse custo desigual, gerando desbalanceamento de carga (threads que pegam números maiores demoram mais, enquanto as outras ficam ociosas consumindo energia sem produzir trabalho). Com `schedule(dynamic)` e `schedule(guided)`, a distribuição ocorre em tempo de execução, reduzindo o tempo ocioso. O `guided` especificamente entrega blocos grandes no início e menores ao final, o que corresponde à granularidade decrescente da pergunta de pesquisa.

## 3. Correspondência entre a pergunta e as ferramentas do OpenMP

| Conceito da pergunta | Implementação |
|---|---|
| Blocos de tamanho fixo | `schedule(static, chunk)` |
| Escalonamento dinâmico | `schedule(dynamic, chunk)` |
| Granularidade decrescente | `schedule(guided, chunk)` |

## 4. Métricas

- **Tempo de execução** — base para as demais métricas.
- **Speedup** e **eficiência** — exigidas pelo protocolo da disciplina; comparam sequencial vs. paralelo, não respondem diretamente à pergunta de pesquisa.
- **Custo energético (Primos/Joule)** — métrica central, responde diretamente à hipótese.
- **Energy-Delay Product (EDP = energia × tempo)** — captura o trade-off entre tempo de execução e energia gasta; útil para discutir casos em que um schedule é mais rápido mas gasta mais energia (ou vice-versa).

## 5. Estimativa de energia (sem acesso a RAPL/perf)

Sem hardware de medição direta disponível, a estimativa usada é:

```
energia_estimada = tempo_execução × TDP_do_processador × utilização_média_de_CPU
```

Essa é uma **aproximação indireta**, não uma medição direta — essa limitação deve ser registrada explicitamente na seção de ameaças à validade do artigo.

## 6. Protocolo experimental

- Todas as execuções da coleta oficial devem ocorrer na **mesma máquina**, sem trocar de hardware no meio, para não invalidar a comparação entre schedules.
- Registrar modelo do processador, RAM e sistema operacional antes da coleta.
- Realizar pelo menos uma execução de aquecimento antes de gravar dados.
- Executar cada configuração (schedule × número de threads) pelo menos 10 vezes.
- Configurações mínimas: sequencial, e paralelo com 1, 2, 4 e 8 threads, para cada schedule.
- Reportar média/mediana e uma medida de dispersão (desvio padrão).
- Evitar rodar outros programas pesados durante a coleta.

## 7. Bibliografia

1. CIORBA, F. M.; IWAINSKY, C.; BUDER, P. **OpenMP loop scheduling revisited: making a case for more schedules**. In: International Workshop on OpenMP (IWOMP), 14., 2018, Barcelona. *Anais...* Springer, 2018. p. 21-36.
2. LIU, S.; ZHANG, Y.; SUN, X. **An improved guided loop scheduling algorithm for OpenMP**. 2010.
3. VALTER, H.; KARLSSON, A.; PERICÀS, M. **Energy-efficiency evaluation of OpenMP loop transformations and runtime constructs**. arXiv:2209.04317, 2022.
4. HWANG, S.; CHUNG, K.; KIM, D. **Load Balanced Parallel Prime Number Generator with Sieve of Eratosthenes on Cluster Computers**. In: IEEE International Conference on Computer and Information Technology (CIT), 7., 2007, Aizu-Wakamatsu, Japão. *Anais...* p. 295-299. DOI: 10.1109/CIT.2007.139. (Nota: usa memória distribuída/MPI, não OpenMP — citar apenas como evidência de que o desbalanceamento de carga em geração paralela de primos é um problema conhecido, não sobre `schedule`.)
