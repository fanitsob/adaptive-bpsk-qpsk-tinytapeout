import numpy as np
import matplotlib.pyplot as plt
import math
import csv

# Parameters
ESN0_DB = np.arange(0, 19, 0.5)
BER_TARGET = 1e-3
SYMBOL_RATE = 1e6  # 1 Msymbol/s (simulation assumption)

ber_bpsk = []
ber_qpsk = []
adaptive_mode = []
adaptive_rate = []

def q_function(x):
    return 0.5 * math.erfc(x / math.sqrt(2))

for esn0_db in ESN0_DB:

    esn0 = 10 ** (esn0_db / 10)

    # Theoretical uncoded BER
    pb_bpsk = q_function(math.sqrt(2 * esn0))
    pb_qpsk = q_function(math.sqrt(esn0))

    ber_bpsk.append(pb_bpsk)
    ber_qpsk.append(pb_qpsk)

    # Select highest-rate mode meeting the BER target
    if pb_qpsk <= BER_TARGET:
        mode = "QPSK"
        rate = 2 * SYMBOL_RATE

    elif pb_bpsk <= BER_TARGET:
        mode = "BPSK"
        rate = SYMBOL_RATE

    else:
        mode = "OUTAGE"
        rate = 0

    adaptive_mode.append(mode)
    adaptive_rate.append(rate / 1e6)

# Save numerical results
with open("test/adaptive_throughput.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow([
        "EsN0_dB",
        "BPSK_BER",
        "QPSK_BER",
        "Selected_Mode",
        "Nominal_Rate_Mbps"
    ])

    for i in range(len(ESN0_DB)):
        writer.writerow([
            ESN0_DB[i],
            ber_bpsk[i],
            ber_qpsk[i],
            adaptive_mode[i],
            adaptive_rate[i]
        ])

# Plot
fig, axes = plt.subplots(2, 1, figsize=(10, 8), sharex=True)

axes[0].semilogy(
    ESN0_DB, ber_bpsk,
    label="BPSK", color="blue"
)

axes[0].semilogy(
    ESN0_DB, ber_qpsk,
    label="QPSK", color="red"
)

axes[0].axhline(
    BER_TARGET,
    color="black",
    linestyle="--",
    label="BER target"
)

axes[0].set_ylabel("BER")
axes[0].set_ylim(1e-9, 1)
axes[0].set_title("BER at Fixed Symbol Energy")
axes[0].grid(True, which="both")
axes[0].legend()

axes[1].step(
    ESN0_DB,
    adaptive_rate,
    where="post",
    color="green",
    linewidth=2
)

axes[1].set_xlabel("Es/N0 (dB)")
axes[1].set_ylabel("Nominal Bit Rate (Mbps)")
axes[1].set_yticks([0, 1, 2])
axes[1].set_title("BER-Constrained Adaptive Modulation")
axes[1].grid(True)

plt.tight_layout()
plt.savefig("test/adaptive_throughput.png", dpi=300)

# Print mode transition points
previous_mode = None

for snr, mode in zip(ESN0_DB, adaptive_mode):
    if mode != previous_mode:
        print(f"Es/N0 = {snr:.1f} dB -> {mode}")
        previous_mode = mode

print("Adaptive throughput simulation completed.")
