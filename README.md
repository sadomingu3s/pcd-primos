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
```

**Importante:** a coleta oficial (a que vai para o artigo) deve ser rodada em **uma única máquina**, do início ao fim, sem trocar de ambiente — ver `docs/DOCS.md` para o motivo.
iciência, energia estimada)
- [ ] Artigo redigido
