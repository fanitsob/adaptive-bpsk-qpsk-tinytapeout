import math

BER_VALUES = [0.005, 0.01, 0.02, 0.04, 0.06, 0.08]

CONFIGS = [
    (128, 2, 8),
    (256, 4, 16)
]


def probability(n, k, p):
    return math.comb(n, k) * p**k * (1-p)**(n-k)


for ber in BER_VALUES:

    print(f"\nTRUE BER = {ber:.1%}")

    for n, low, high in CONFIGS:

        p_qpsk = sum(
            probability(n, k, ber)
            for k in range(low + 1)
        )

        p_bpsk = sum(
            probability(n, k, ber)
            for k in range(high, n + 1)
        )

        p_hold = 1 - p_qpsk - p_bpsk

        print(
            f"Window={n:3d} | "
            f"QPSK={p_qpsk:6.2%} | "
            f"HOLD={p_hold:6.2%} | "
            f"BPSK={p_bpsk:6.2%}"
        )
import math

BER_VALUES = [0.005, 0.01, 0.02, 0.04, 0.06, 0.08]

CONFIGS = [
    (128, 2, 8),
    (256, 4, 16)
]


def probability(n, k, p):
    return math.comb(n, k) * p**k * (1-p)**(n-k)


for ber in BER_VALUES:

    print(f"\nTRUE BER = {ber:.1%}")

    for n, low, high in CONFIGS:

        p_qpsk = sum(
            probability(n, k, ber)
            for k in range(low + 1)
        )

        p_bpsk = sum(
            probability(n, k, ber)
            for k in range(high, n + 1)
        )

        p_hold = 1 - p_qpsk - p_bpsk

        print(
            f"Window={n:3d} | "
            f"QPSK={p_qpsk:6.2%} | "
            f"HOLD={p_hold:6.2%} | "
            f"BPSK={p_bpsk:6.2%}"
        )
