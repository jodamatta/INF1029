import csv
import matplotlib.pyplot as plt

CSV_FILE = "resultados.csv"

ns, t_esc, t_vet, speedups = [], [], [], []

with open(CSV_FILE, newline="") as f:
    reader = csv.DictReader(f)
    for row in reader:
        try:
            n = int(row["N"])
            te = float(row["escalar_ms"])
            tv = float(row["vetorial_ms"])
            sp = float(row["speedup"])
            ns.append(n)
            t_esc.append(te)
            t_vet.append(tv)
            speedups.append(sp)
        except (ValueError, KeyError):
            continue

if not ns:
    print(f"Nenhum dado encontrado em {CSV_FILE}")
    exit(1)

# --- Gráfico 1: Tempo vs N (escala log-log) ---
fig, ax = plt.subplots(figsize=(9, 5))
ax.plot(ns, t_esc, marker="o", label="Escalar", linewidth=2)
ax.plot(ns, t_vet, marker="s", label="Vetorial (AVX/FMA)", linewidth=2)
ax.set_xscale("log", base=2)
ax.set_yscale("log")
ax.set_xlabel("N (número de incógnitas)", fontsize=12)
ax.set_ylabel("Tempo (ms)", fontsize=12)
ax.set_title("Tempo de execução: Escalar vs Vetorial", fontsize=13)
ax.legend(fontsize=11)
ax.grid(True, which="both", linestyle="--", alpha=0.5)
ax.set_xticks(ns)
ax.set_xticklabels([str(n) for n in ns], rotation=45, ha="right")
plt.tight_layout()
plt.savefig("grafico_tempo.png", dpi=150)
print("Salvo: grafico_tempo.png")
plt.close()

# --- Gráfico 2: Speedup vs N ---
fig, ax = plt.subplots(figsize=(9, 5))
ax.plot(ns, speedups, marker="^", color="green", linewidth=2, label="Speedup")
ax.axhline(y=1.0, color="gray", linestyle="--", linewidth=1, label="Speedup = 1 (sem ganho)")
ax.set_xscale("log", base=2)
ax.set_xlabel("N (número de incógnitas)", fontsize=12)
ax.set_ylabel("Speedup (escalar / vetorial)", fontsize=12)
ax.set_title("Speedup: Vetorial AVX/FMA vs Escalar", fontsize=13)
ax.legend(fontsize=11)
ax.grid(True, which="both", linestyle="--", alpha=0.5)
ax.set_xticks(ns)
ax.set_xticklabels([str(n) for n in ns], rotation=45, ha="right")
plt.tight_layout()
plt.savefig("grafico_speedup.png", dpi=150)
print("Salvo: grafico_speedup.png")
plt.close()
