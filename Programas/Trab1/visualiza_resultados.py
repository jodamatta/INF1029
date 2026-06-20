import numpy as np
import matplotlib.pyplot as plt

# Sizes tested
sizes = [1024, 2048, 3072, 4096]

# Number of runs per size
runs_per_size = 10

with open("Programas/Trab1/tempos.csv", "r") as f:
    raw = f.read().strip()

tokens = [x.strip() for x in raw.split(",")]

times = []

for token in tokens:
    try:
        times.append(float(token))
    except ValueError:
        pass

cpu_avg = []
gpu_avg = []
speedup = []

idx = 0

for size in sizes:
    cpu_runs = []
    gpu_runs = []

    for _ in range(runs_per_size):
        cpu_runs.append(times[idx])
        gpu_runs.append(times[idx + 1])
        idx += 2

    cpu_mean = np.mean(cpu_runs)
    gpu_mean = np.mean(gpu_runs)

    cpu_avg.append(cpu_mean)
    gpu_avg.append(gpu_mean)

    speedup.append(cpu_mean / gpu_mean)

print("\nMédia de tempo de execução:\n")

for s, c, g in zip(sizes, cpu_avg, gpu_avg):
    print(
        f"N={s:4d} | CPU={c:10.2f} ms | GPU={g:10.2f} ms | Speedup={c/g:.2f}x"
    )

# -------------------------------------------------
# Graph 1: Execution Time
# -------------------------------------------------

plt.figure(figsize=(8,5))
plt.plot(sizes, cpu_avg, marker="o", label="CPU Threads")
plt.plot(sizes, gpu_avg, marker="o", label="GPU CUDA")

plt.xlabel("Tamanho da Matriz (N)")
plt.ylabel("Tempo de execução (ms)")
plt.title("Tempo de execução: CPU vs GPU")
plt.legend()
plt.grid(True)

plt.savefig("tempo_execucao.png")
plt.show()

# -------------------------------------------------
# Graph 2: Speedup
# -------------------------------------------------

plt.figure(figsize=(8,5))
plt.plot(sizes, speedup, marker="o")

plt.xlabel("Tamanho da Matrize (N)")
plt.ylabel("Speedup (CPU/GPU)")
plt.title("GPU Speedup")
plt.grid(True)

plt.savefig("speedup.png")
plt.show()