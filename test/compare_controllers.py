import csv
import matplotlib.pyplot as plt

# Read existing BER simulation results
windows = []
errors = []
original_modes = []

with open("test/ber_results.csv", newline="") as file:
    reader = csv.DictReader(file)

    for row in reader:
        windows.append(int(row["Window"]))
        errors.append(int(row["Errors"]))
        original_modes.append(int(row["Mode"]))

# Improved controller:
# Require two consecutive windows before switching modes
mode = 0
pending_mode = None
consecutive = 0

improved_modes = []

for error_count in errors:

    if error_count <= 2:
        requested_mode = 1  # QPSK

    elif error_count >= 8:
        requested_mode = 0  # BPSK

    else:
        requested_mode = None

    if requested_mode is None or requested_mode == mode:
        pending_mode = None
        consecutive = 0

    elif requested_mode == pending_mode:
        consecutive += 1

    else:
        pending_mode = requested_mode
        consecutive = 1

    if consecutive >= 2:
        mode = requested_mode
        pending_mode = None
        consecutive = 0

    improved_modes.append(mode)


def count_switches(modes):
    return sum(
        modes[i] != modes[i - 1]
        for i in range(1, len(modes))
    )


original_switches = count_switches(original_modes)
improved_switches = count_switches(improved_modes)

print("Original controller switches:", original_switches)
print("Improved controller switches:", improved_switches)

# Plot comparison
plt.figure(figsize=(12, 6))

plt.step(
    windows,
    original_modes,
    where="post",
    label="Original controller",
    linewidth=2,
    color="red"
)

plt.step(
    windows,
    improved_modes,
    where="post",
    label="Improved controller (2 windows)",
    linewidth=2,
    linestyle="--",
    color="blue"
)

plt.yticks([0, 1], ["BPSK", "QPSK"])
plt.xlabel("Observation Window")
plt.ylabel("Modulation Mode")
plt.title("Adaptive BPSK/QPSK Controller Comparison")
plt.grid(True)
plt.legend()
plt.tight_layout()

plt.savefig("test/controller_comparison.png", dpi=300)

print("Figure saved to test/controller_comparison.png")

