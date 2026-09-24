#!/bin/bash
# Coleta oficial dos experimentos: static/dynamic/guided x threads x repetições
# Rodar UMA VEZ, na máquina escolhida como oficial, sem interromper.
# Uso: bash run.sh   (execute de dentro da pasta src/, com os binários já compilados)

N=20000000
REPS=10
THREADS=(1 2 4 8)
SCHEDULES=(static dynamic guided)

mkdir -p ../data
SAIDA=../data/resultados.csv
BASELINE=../data/baseline.txt

for bin in seq "${SCHEDULES[@]}"; do
    if [ ! -f "./$bin" ]; then
        echo "Erro: não encontrei ./$bin. Compile antes de rodar este script."
        exit 1
    fi
done

echo "== Baseline sequencial (N=$N) =="
inicio=$(date +%s.%N)
resultado_seq=$(./seq $N)
fim=$(date +%s.%N)
tempo_seq=$(awk "BEGIN {printf \"%.6f\", $fim - $inicio}")
primos_seq=$(echo "$resultado_seq" | grep -o 'primos=[0-9]*' | cut -d'=' -f2)
echo "$tempo_seq" > "$BASELINE"
echo "Sequencial: ${tempo_seq}s, primos=$primos_seq"

echo ""
echo "== Aquecimento (descartado) =="
for sched in "${SCHEDULES[@]}"; do
    for t in "${THREADS[@]}"; do
        ./$sched $N $t > /dev/null
    done
done
echo "Aquecimento concluído."

echo ""
echo "== Coleta oficial ($REPS repetições por configuração) =="
echo "schedule,threads,rep,primos,tempo" > "$SAIDA"

for sched in "${SCHEDULES[@]}"; do
    for t in "${THREADS[@]}"; do
        for r in $(seq 1 $REPS); do
            linha=$(./$sched $N $t)
            primos=$(echo "$linha" | cut -d',' -f3)
            tempo=$(echo "$linha" | cut -d',' -f4)

            if [ "$primos" != "$primos_seq" ]; then
                echo "AVISO: $sched com $t threads (rep $r) deu $primos primos, esperado $primos_seq"
            fi

            echo "$sched,$t,$r,$primos,$tempo" >> "$SAIDA"
        done
        echo "Concluído: $sched com $t threads"
    done
done

echo ""
echo "Coleta concluída."
echo "Resultados em: $SAIDA"
echo "Baseline em:   $BASELINE"
