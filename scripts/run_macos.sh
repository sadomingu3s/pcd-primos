set -u

CC="${CC:-clang}"
OMP_INC="${OMP_INC:-/opt/homebrew/opt/libomp/include}"
OMP_LIB="${OMP_LIB:-/opt/homebrew/opt/libomp/lib}"

BASE_DIR="$(pwd)"
SRC_DIR="$BASE_DIR/src"
BIN_DIR="$BASE_DIR/bin"
RES_DIR="$BASE_DIR/data/resultados_macos"
PWR_DIR="$RES_DIR/power_logs"
CSV="${CSV:-$RES_DIR/results.csv}"

OPTS=(O0 O1 O2 O3)
THREADS=(1 2 4 8)
CHUNKS=(1000 10000 100000)
NS=(1000000000)
REPS=3

MEASURE_POWER="${MEASURE_POWER:-1}"
INTERVAL_MS=100

mkdir -p "$BIN_DIR" "$RES_DIR" "$PWR_DIR"

# $1 = log do powermetrics, $2 = tempo do programa (s), $3 = potência ociosa (mW)
# -> "avg_mW,energia_J,log_s"
# Integra o log INTEIRO (soma de potência × tempo real de cada amostra) e subtrai o consumo ocioso
# do trecho de padding antes/depois do programa:
#   E_prog = Σ P_i·dt_i − P_idle·Σ dt_i + P_idle·time_s
# Não depende de limiar nem de janela: o padding ocioso se cancela. log_s = Σ dt_i (≈ time_s + padding).
# LC_ALL=C evita vírgula decimal (pt_BR), que quebrava o CSV.
power_stats() {
    LC_ALL=C awk -v t="$2" -v idle="$3" '
        /^\*\*\* Sampled system activity/ { if (match($0, /\([0-9.]+ms elapsed\)/)) { d = substr($0, RSTART+1, RLENGTH-2); sub(/ms elapsed/, "", d); cur = d + 0 } }
        /^CPU Power:/ { n++; e += ($3 + 0) * (cur > 0 ? cur : 100) / 1000; w += (cur > 0 ? cur : 100) / 1000 }
        END {
            if (n < 3 || t == "NA" || idle == "NA") { printf("NA,NA,NA"); exit }
            ej = e / 1000 - (idle / 1000) * w + (idle / 1000) * t
            printf("%.1f,%.3f,%.2f", ej / t * 1000, ej, w)
        }' "$1"
}

# Potência ociosa (mW): média de 5 s de amostras com a máquina parada
measure_idle() {
    sudo powermetrics -i 100 -n 50 -s cpu_power 2>/dev/null |
        LC_ALL=C awk '/^CPU Power:/ { s += $3; c++ } END { if (c > 0) printf("%.1f", s / c); else printf("NA") }'
}

if [ "$MEASURE_POWER" = "1" ]; then
    echo "powermetrics exige sudo. Autenticando..."
    sudo -v || exit 1
    echo "Medindo potência ociosa (5 s) — deixe o Mac parado..."
    IDLE_MW="$(measure_idle)"
    echo "Potência ociosa da CPU: ${IDLE_MW} mW"
else
    IDLE_MW="NA"
fi

echo "source,opt,n,chunk,threads,rep,primes,time_s,avg_cpu_mw,energy_j,log_s" > "$CSV"

run_one() {
    # $1=bin  $2=source  $3=opt  $4=n  $5=chunk  $6=threads  $7=rep ; $8.. = args do binário
    local bin="$1" name="$2" opt="$3" n="$4" chunk="$5" th="$6" rep="$7"
    shift 7

    local pid="" plog=""
    if [ "$MEASURE_POWER" = "1" ]; then
        plog="$PWR_DIR/${name}_${opt}_n${n}_c${chunk}_t${th}_r${rep}.txt"
        sudo powermetrics -i "$INTERVAL_MS" -s cpu_power > "$plog" 2>/dev/null &
        pid=$!
        sleep 1
    fi

    local out rc
    out=$(OMP_NUM_THREADS="$th" "$bin" "$@" 2>&1)
    rc=$?

    if [ -n "$pid" ]; then
        sleep 0.5
        sudo kill -INT "$pid" 2>/dev/null   # INT deixa o powermetrics descarregar o buffer do arquivo
        wait "$pid" 2>/dev/null
        sleep 0.3
        sudo pkill -x powermetrics 2>/dev/null   # só depois de esperar: garante que não sobrou processo
    fi

    local primes tempo avg="NA" energia="NA" janela="NA"
    primes=$(printf '%s\n' "$out" | sed -nE 's/.*Quantidade de primos: *([0-9]+).*/\1/p' | tail -n 1)
    tempo=$(printf '%s\n' "$out" | sed -nE 's/.*Tempo\(s\): *([0-9.]+).*/\1/p' | tail -n 1)
    primes="${primes:-NA}"
    tempo="${tempo:-NA}"

    if [ -n "$plog" ]; then
        if ! grep -q '^CPU Power:' "$plog" 2>/dev/null; then
            echo "Erro: sem linhas 'CPU Power:' em $plog (log vazio ou formato diferente)"
        fi
        IFS=',' read -r avg energia janela <<< "$(power_stats "$plog" "$tempo" "$IDLE_MW")"
    fi

    if [ $rc -ne 0 ] || [ "$tempo" = "NA" ]; then
        echo "Erro:  $name -$opt n=$n chunk=$chunk t=$th rep=$rep: código $rc, saída não reconhecida"
    fi

    echo "$name,$opt,$n,$chunk,$th,$rep,$primes,$tempo,$avg,$energia,$janela" >> "$CSV"
}

for src in "$SRC_DIR"/*.c; do
    name="$(basename "$src" .c)"

    for opt in "${OPTS[@]}"; do
        bin="$BIN_DIR/${name}_${opt}"
        echo "=== Compilando $name com -$opt ==="

        if [ "$name" = "serial" ]; then
            "$CC" "-$opt" "$src" -o "$bin" -lm
        else
            "$CC" "-$opt" -Xpreprocessor -fopenmp -I"$OMP_INC" -L"$OMP_LIB" -lomp "$src" -o "$bin" -lm
        fi
        if [ $? -ne 0 ]; then
            echo "Erro: Falha ao compilar $name -$opt. Pulando."
            continue
        fi

        for n in "${NS[@]}"; do
            if [ "$name" = "serial" ]; then
                # serial não depende de threads nem de chunk
                for rep in $(seq 1 $REPS); do
                    echo "▶ $name -$opt n=$n rep=$rep"
                    run_one "$bin" "$name" "$opt" "$n" 0 1 "$rep" "$n"
                done
            else
                for chunk in "${CHUNKS[@]}"; do
                    for th in "${THREADS[@]}"; do
                        for rep in $(seq 1 $REPS); do
                            echo "▶ $name -$opt n=$n chunk=$chunk t=$th rep=$rep"
                            run_one "$bin" "$name" "$opt" "$n" "$chunk" "$th" "$rep" "$n" "$chunk" "$th"
                        done
                    done
                done
            fi
        done
    done
done

if [ "$MEASURE_POWER" = "1" ]; then
    sudo chown -R "$(whoami)" "$RES_DIR" 2>/dev/null
fi

echo ""
echo "Concluído. Resultados em: $CSV"