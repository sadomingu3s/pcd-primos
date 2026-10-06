#Código escrito com auxílio IA (Gemini)
import subprocess
import time
import csv
import re
from datetime import datetime

# Configurações do experimento
N = "1000000000"  # 1e9
RUNS = 3
CHUNK_SIZES = ["1000", "10000", "100000"]
THREADS = ["1", "2", "4", "8"]
OPTIMIZATIONS = ["O0", "O1", "O2", "O3"]
PROGRAMS = ["serial", "omp_static", "omp_dynamic", "omp_guided"]

regex_output = re.compile(r"Quantidade de primos:\s*(\d+)[\s,]*Tempo\(s\):\s*([0-9.]+)")

def compile_codes():
    print("Iniciando compilação...")
    for prog in PROGRAMS:
        for opt in OPTIMIZATIONS:
            source = f"{prog}.c"
            exe = f"{prog}_{opt}.exe"
            
            cmd = ["gcc", source, "-o", exe, "-lm", f"-{opt}"]
            if prog != "serial":
                cmd.insert(1, "-fopenmp")
                
            print(f"Compilando: {' '.join(cmd)}")
            subprocess.run(cmd, check=True)
    print("Compilação concluída!\n")

def run_experiment():
    csv_filename = "results.csv"
    
    with open(csv_filename, mode="w", newline="") as file:
        writer = csv.writer(file)
       
        writer.writerow(["Programa", "Otimizacao", "Chunk_Size", "Threads", "Run", "N", "Primos_Encontrados", "Tempo_Segundos", "Inicio", "Fim"])
        
        for prog in PROGRAMS:
            for opt in OPTIMIZATIONS:
                exe = f"{prog}_{opt}.exe"
                
                if prog == "serial":
                    for run in range(1, RUNS + 1):
                        print(f"Executando {exe} [Run {run}/{RUNS}]")
                        cmd = [f"./{exe}", N]
                        
                        inicio = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
                        result = subprocess.run(cmd, capture_output=True, text=True)
                        fim = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
                        
                        match = regex_output.search(result.stdout)
                        if match:
                            primos, tempo = match.groups()
                            writer.writerow([prog, opt, "NA", "NA", run, N, primos, tempo, inicio, fim])
                        else:
                            print(f"Erro ao ler saída: {result.stdout}")
                        
                        time.sleep(1)
                else:
                    for chunk in CHUNK_SIZES:
                        for thread in THREADS:
                            for run in range(1, RUNS + 1):
                                print(f"Executando {exe} (Chunk: {chunk}, Threads: {thread}) [Run {run}/{RUNS}]")
                                cmd = [f"./{exe}", N, chunk, thread]
                                
                                inicio = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
                                result = subprocess.run(cmd, capture_output=True, text=True)
                                fim = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
                                
                                match = regex_output.search(result.stdout)
                                if match:
                                    primos, tempo = match.groups()
                                    writer.writerow([prog, opt, chunk, thread, run, N, primos, tempo, inicio, fim])
                                else:
                                    print(f"Erro ao ler saída: {result.stdout}")
                                
                                time.sleep(1)

if __name__ == "__main__":
    compile_codes()
    run_experiment()
    print("Experimentos finalizados. Resultados salvos em results.csv")