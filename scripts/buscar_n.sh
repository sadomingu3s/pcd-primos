#!/bin/bash
# Varia N e mede o tempo de execução do programa sequencial (./seq)
# Uso: bash buscar_n.sh

BIN=../src/seq

if [ ! -f "$BIN" ]; then
    echo "Erro: não encontrei $BIN. Compile antes com: gcc -O2 primos_seq.c -o seq -lm"
    exit 1
fi

NS=(1000000 2000000 5000000 10000000 20000000 50000000 100000000)
SAIDA=exploracao_n.csv

echo "N,tempo_segundos" > "$SAIDA"
for N in "${NS[@]}"; do
    inicio=$(date +%s.%N)
    resultado=$($BIN $N)
    fim=$(date +%s.%N)
    tempo=$(awk "BEGIN {printf \"%.3f\", $fim - $inicio}")
    echo "$N,$tempo" >> "$SAIDA"
    echo "N=$N -> ${tempo}s"
done

echo ""
echo "Resultados salvos em $SAIDA"
