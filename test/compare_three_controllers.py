import csv
import matplotlib.pyplot as plt

windows = []
errors = []

with open("test/ber_results.csv", newline="") as f:
    reader = csv.DictReader(f)
    for row in reader:
        windows.append(int(row["Window"]))
        errors.append(int(row["Errors"]))


def simulate(strategy):
    mode = 0
    pending = None
    count = 0
    history = []

    for e in errors:

        if e <= 2:
            target = 1
        elif e >= 8:
            target = 0
        else:
            target = None

        if strategy == "original":
            if target is not None:
                mode = target

        elif strategy == "two_window":
            if target is None or target == mode:
                pending = None
                count = 0
            elif target == pending:
                count += 1
            else:
                pending = target
                count = 1

            if count >= 2:
                mode = target
                pending = None
                count = 0

        elif strategy == "fast_bpsk":
            if target == 0:
                mode = 0
                count = 0

            elif target == 1:
                if mode == 0:
                    count += 1
                    if count >= 2:
                        mode = 1
                        count = 0
                else:
                    count = 0

            else:
                count = 0

        history.append(mode)

    return history


def count_switches(history):
    return sum(
        history[i] != history[i - 1]
        for i in range(1, len(history))
    )


strategies = {
    "Original": simulate("original"),
    "Two-window": simulate("two_window"),
    "Fast BPSK / Stable QPSK": simulate("fast_bpsk")
}

for name, history in strategies.items():
    switches = count_switches(history)
    qpsk_percent = 100 * sum(history) / len(history)

    print(
        f"{name}: "
        f"switches={switches}, "
        f"QPSK usage={qpsk_percent:.1f}%"
    )

plt.figure(figsize=(12, 6))

styles = [
    ("Original", "red", "-"),
    ("Two-window", "blue", "--"),
    ("Fast BPSK / Stable QPSK", "green", ":")
]

for name, color, linestyle in styles:
    plt.step(
        windows,
        strategies[name],
        where="post",
        label=name,
        color=color,
        linestyle=linestyle,
        linewidth=2
    )

plt.yticks([0, 1], ["BPSK", "QPSK"])
plt.xlabel("Observation Window")
plt.ylabel("Modulation Mode")
plt.title("Comparison of Three Adaptive Modulation Strategies")
plt.grid(True)
plt.legend()
plt.tight_layout()

plt.savefig("test/three_controller_comparison.png", dpi=300)

print("Figure saved to test/three_controller_comparison.png")

