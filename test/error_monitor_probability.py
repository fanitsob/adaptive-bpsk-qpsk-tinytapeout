import math
import csv

WINDOW_SIZE = 128

LOW_THRESHOLD = 2
HIGH_THRESHOLD = 8

BER_VALUES = [
    0.001,
    0.005,
    0.01,
    0.02,
    0.04,
    0.06,
    0.08,
    0.10
]


def binomial_probability(n, k, p):
    return (
        math.comb(n, k)
        * (p ** k)
        * ((1 - p) ** (n - k))
    )


results = []

print("\nERROR MONITOR PROBABILITY ANALYSIS")
print("-" * 75)

for ber in BER_VALUES:

    p_qpsk = sum(
        binomial_probability(WINDOW_SIZE, k, ber)
        for k in range(LOW_THRESHOLD + 1)
    )

    p_bpsk = sum(
        binomial_probability(WINDOW_SIZE, k, ber)
        for k in range(HIGH_THRESHOLD, WINDOW_SIZE + 1)
    )

    p_hold = 1 - p_qpsk - p_bpsk

    expected_errors = WINDOW_SIZE * ber

    results.append([
        ber,
        expected_errors,
        p_qpsk,
        p_hold,
        p_bpsk
    ])

    print(
        f"BER={ber:6.3%} | "
        f"Expected errors={expected_errors:5.2f} | "
        f"QPSK={p_qpsk:6.2%} | "
        f"HOLD={p_hold:6.2%} | "
        f"BPSK={p_bpsk:6.2%}"
    )


with open(
    "test/error_monitor_probability.csv",
    "w",
    newline=""
) as f:

    writer = csv.writer(f)

    writer.writerow([
        "True_BER",
        "Expected_Errors",
        "P_QPSK",
        "P_HOLD",
        "P_BPSK"
    ])

    writer.writerows(results)


print("-" * 75)
print("Probability analysis completed.")
print("Results saved to test/error_monitor_probability.csv")
