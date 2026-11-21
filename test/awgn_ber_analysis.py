import numpy as np
import matplotlib.pyplot as plt
import csv
import math

# Simulation parameters
EBN0_DB = np.arange(0, 13, 2)
NUM_BITS = 200000

rng = np.random.default_rng(42)

results = []


def simulate_bpsk(ebn0_db):
    bits = rng.integers(0, 2, NUM_BITS)

    # BPSK modulation
    symbols = 1 - 2 * bits

    ebn0 = 10 ** (ebn0_db / 10)
    sigma = np.sqrt(1 / (2 * ebn0))

    # AWGN channel
    noise = sigma * rng.standard_normal(NUM_BITS)
    received = symbols + noise

    # Hard-decision demodulation
    detected = (received < 0).astype(int)

    return np.mean(bits != detected)


def simulate_qpsk(ebn0_db):
    bits = rng.integers(0, 2, NUM_BITS)

    i_bits = bits[0::2]
    q_bits = bits[1::2]

    # Gray-labeled QPSK symbols, normalized energy Es = 1
    i = (1 - 2 * i_bits) / np.sqrt(2)
    q = (1 - 2 * q_bits) / np.sqrt(2)

    symbols = i + 1j * q

    ebn0 = 10 ** (ebn0_db / 10)

    # QPSK carries 2 bits/symbol, Eb = Es/2
    sigma = np.sqrt(1 / (4 * ebn0))

    noise = sigma * (
        rng.standard_normal(len(symbols))
        + 1j * rng.standard_normal(len(symbols))
    )

    received = symbols + noise

    detected_i = (received.real < 0).astype(int)
    detected_q = (received.imag < 0).astype(int)

    detected = np.empty(NUM_BITS, dtype=int)
    detected[0::2] = detected_i
    detected[1::2] = detected_q

    return np.mean(bits != detected)


for ebn0_db in EBN0_DB:

    ber_bpsk = simulate_bpsk(ebn0_db)
    ber_qpsk = simulate_qpsk(ebn0_db)

    # Theoretical BER for coherent BPSK / Gray QPSK in AWGN
    ebn0 = 10 ** (ebn0_db / 10)

    theoretical_ber = 0.5 * math.erfc(
        math.sqrt(ebn0)
    )

    results.append([
        ebn0_db,
        ber_bpsk,
        ber_qpsk,
        theoretical_ber
    ])

    print(
        f"Eb/N0={ebn0_db:2d} dB | "
        f"BPSK BER={ber_bpsk:.6f} | "
        f"QPSK BER={ber_qpsk:.6f}"
    )


# Save results
with open("test/awgn_ber_results.csv", "w", newline="") as f:
    writer = csv.writer(f)

    writer.writerow([
        "EbN0_dB",
        "BPSK_BER",
        "QPSK_BER",
        "Theoretical_BER"
    ])

    writer.writerows(results)


# Create BER graph
plt.figure(figsize=(10, 6))

plt.semilogy(
    EBN0_DB,
    [r[1] for r in results],
    "bo-",
    label="BPSK simulated"
)

plt.semilogy(
    EBN0_DB,
    [r[2] for r in results],
    "rs-",
    label="QPSK simulated"
)

plt.semilogy(
    EBN0_DB,
    [r[3] for r in results],
    "k--",
    label="Theoretical BER"
)

plt.xlabel("Eb/N0 (dB)")
plt.ylabel("Bit Error Rate")
plt.title("BPSK and QPSK Performance over AWGN")
plt.grid(True, which="both")
plt.legend()
plt.tight_layout()

plt.savefig("test/awgn_ber_comparison.png", dpi=300)

print("AWGN BER simulation completed.")
print("Figure saved to test/awgn_ber_comparison.png")
