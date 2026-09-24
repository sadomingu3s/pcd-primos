#!/bin/bash
# Varredura de tamanho de chunk, com threads fixo em 8 (a config mais rápida/estável).
# Complementa o run.sh original: aquele varia threads com chunk fixo (1000);
# este varia chunk com threads fixo, pra investigar o parâmetro isoladamente.
# Uso: bash run_chunk.sh   (execute de dentro de src/)

N=20000000
THREADS=8
REPS=10
SCHEDULES=(static dynamic guided)

# 100 e 1000: chunk pequeno (o que já testamos)
# 10000 e 100000: chunk médio
# 2500000 = N/THREADS: bloco único e contíguo por thread (equivale a "static sem chunk")
CHUNKS=(100 1000 10000 100000 2500000)

mkdir -p ../data
SAIDA=../data/resultados_chunk.csv

for sched in "${SCHEDULES[@]}"; do
    if [ ! -f "./$sched" ]; then
        echo "Erro: não encontrei ./$sched. Compile antes de rodar este script."
        exit 1
    fi
done

echo "schedule,threads,chunk,rep,primos,tempo" > "$SAIDA"

for sched in "${SCHEDULES[@]}"; do
    for c in "${CHUNKS[@]}"; do
        # aquecimento (descartado)
        ./$sched $N $THREADS $c > /dev/null

        for r in $(seq 1 $REPS); do
            linha=$(./$sched $N $THREADS $c)
            primos=$(echo "$linha" | cut -d',' -f3)
            tempo=$(echo "$linha" | cut -d',' -f4)
            echo "$sched,$THREADS,$c,$r,$primos,$tempo" >> "$SAIDA"
        done
        echo "Concluído: $sched, chunk=$c"
    done
done

echo ""
echo "Coleta de chunk concluída. Resultados em: $SAIDA"
