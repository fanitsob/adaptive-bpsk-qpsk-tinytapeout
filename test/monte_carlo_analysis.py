import random
import statistics
import csv

WINDOW_SIZE = 128
NUM_RUNS = 1000

BER_PROFILE = (
    [0.005] * 20 +
    [0.02]  * 20 +
    [0.08]  * 20 +
    [0.04]  * 20 +
    [0.005] * 20
)


def simulate(errors, strategy):
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

        if strategy == "Original":
            if target is not None:
                mode = target

        elif strategy == "Two-window":
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

        elif strategy == "Fast BPSK":
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


def response_delay(history):
    # Channel deterioration starts at window 40.
    for i in range(40, 60):
        if history[i] == 0:
            return i - 40

    return 20


strategies = ["Original", "Two-window", "Fast BPSK"]

results = {
    name: {
        "switches": [],
        "qpsk_usage": [],
        "response_delay": []
    }
    for name in strategies
}

random.seed(42)

for run in range(NUM_RUNS):

    errors = []

    for ber in BER_PROFILE:
        error_count = sum(
            random.random() < ber
            for _ in range(WINDOW_SIZE)
        )

        errors.append(error_count)

    for strategy in strategies:
        history = simulate(errors, strategy)

        results[strategy]["switches"].append(
            count_switches(history)
        )

        results[strategy]["qpsk_usage"].append(
            100 * sum(history) / len(history)
        )

        results[strategy]["response_delay"].append(
            response_delay(history)
        )


with open("test/monte_carlo_results.csv", "w", newline="") as f:
    writer = csv.writer(f)

    writer.writerow([
        "Strategy",
        "Mean_Switches",
        "Mean_QPSK_Usage_Percent",
        "Mean_Response_Delay_Windows"
    ])

    for strategy in strategies:
        mean_switches = statistics.mean(
            results[strategy]["switches"]
        )

        mean_qpsk = statistics.mean(
            results[strategy]["qpsk_usage"]
        )

        mean_delay = statistics.mean(
            results[strategy]["response_delay"]
        )

        print(
            f"{strategy}: "
            f"Mean switches={mean_switches:.2f}, "
            f"QPSK usage={mean_qpsk:.2f}%, "
            f"Response delay={mean_delay:.2f} windows"
        )

        writer.writerow([
            strategy,
            round(mean_switches, 3),
            round(mean_qpsk, 3),
            round(mean_delay, 3)
        ])

print("Monte Carlo analysis completed.")
