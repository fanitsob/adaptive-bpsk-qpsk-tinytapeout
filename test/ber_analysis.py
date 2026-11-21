import random
import csv
import matplotlib.pyplot as plt

# Adaptive BPSK/QPSK parameters
WINDOW_SIZE = 128
LOW_THRESHOLD = 2
HIGH_THRESHOLD = 8

NUM_WINDOWS = 100
random.seed(42)

# Channel error probability for each window
ber_profile = (
    [0.005] * 20 +
    [0.02]  * 20 +
    [0.08]  * 20 +
    [0.04]  * 20 +
    [0.005] * 20
)

# Initial mode: BPSK = 0, QPSK = 1
mode = 0

measured_ber = []
mode_history = []
error_history = []

for window in range(NUM_WINDOWS):

    channel_ber = ber_profile[window]

    # Generate 128 random transmitted bits
    transmitted = [
        random.randint(0, 1)
        for _ in range(WINDOW_SIZE)
    ]

    # Simulate independent bit errors
    received = []

    for bit in transmitted:
        if random.random() < channel_ber:
            received.append(bit ^ 1)
        else:
            received.append(bit)

    # Count errors
    errors = sum(
        tx != rx
        for tx, rx in zip(transmitted, received)
    )

    ber = errors / WINDOW_SIZE

    # Adaptive controller
    if errors <= LOW_THRESHOLD:
        mode = 1

    elif errors >= HIGH_THRESHOLD:
        mode = 0

    # Otherwise, maintain previous mode

    measured_ber.append(ber)
    mode_history.append(mode)
    error_history.append(errors)

# Save numerical results
with open("test/ber_results.csv", "w", newline="") as file:

    writer = csv.writer(file)

    writer.writerow([
        "Window",
        "Channel_BER",
        "Measured_BER",
        "Errors",
        "Mode"
    ])

    for i in range(NUM_WINDOWS):
        writer.writerow([
            i,
            ber_profile[i],
            measured_ber[i],
            error_history[i],
            mode_history[i]
        ])

# Plot results
fig, axes = plt.subplots(2, 1, figsize=(11, 7), sharex=True)

axes[0].plot(
    ber_profile,
    label="Channel error probability",
    linestyle="--",
    color="black"
)

axes[0].plot(
    measured_ber,
    label="Measured BER (128 bits)",
    color="blue",
    alpha=0.7
)

axes[0].axhline(
    LOW_THRESHOLD / WINDOW_SIZE,
    color="green",
    linestyle=":",
    label="Low threshold"
)

axes[0].axhline(
    HIGH_THRESHOLD / WINDOW_SIZE,
    color="red",
    linestyle=":",
    label="High threshold"
)

axes[0].set_ylabel("Bit Error Rate")
axes[0].set_title("Adaptive BPSK/QPSK - Error Monitoring")
axes[0].legend()
axes[0].grid(True)

axes[1].step(
    range(NUM_WINDOWS),
    mode_history,
    where="post",
    color="purple"
)

axes[1].set_yticks([0, 1])
axes[1].set_yticklabels(["BPSK", "QPSK"])
axes[1].set_xlabel("Observation Window")
axes[1].set_ylabel("Modulation Mode")
axes[1].set_title("Adaptive Modulation Mode Switching")
axes[1].grid(True)

plt.tight_layout()

plt.savefig("test/adaptive_ber_results.png", dpi=300)

print("BER simulation completed.")
print("Results saved to test/ber_results.csv")
print("Figure saved to test/adaptive_ber_results.png")
