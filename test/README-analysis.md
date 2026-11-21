# Adaptive BPSK/QPSK Performance Analysis

This directory contains Python-based numerical experiments used to evaluate
the adaptive modulation strategy and its error-monitoring behavior.

## Requirements

Python 3 with NumPy and Matplotlib.

Install dependencies:

```bash
python3 -m pip install -r test/requirements-analysis.txt
```

Run all commands from the repository root.

## Analyses

| Script | Description |
|---|---|
| `ber_analysis.py` | Simulates error monitoring and modulation switching across changing channel conditions. |
| `awgn_ber_analysis.py` | Compares simulated BPSK and QPSK BER against theoretical performance over AWGN. |
| `adaptive_throughput.py` | Evaluates BPSK, QPSK and outage decisions as a function of signal-to-noise ratio. |
| `compare_controllers.py` | Compares switching behavior of the original and two-window controllers. |
| `compare_three_controllers.py` | Compares original, two-window and fast-BPSK/stable-QPSK strategies. |
| `compare_window_sizes.py` | Examines the statistical effect of using 128-bit and 256-bit observation windows. |
| `error_monitor_probability.py` | Calculates the probability of low, intermediate and high error counts. |
| `monte_carlo_analysis.py` | Evaluates controller switching, QPSK utilization and response delay across repeated simulations. |

## Running the simulations

For example:

```bash
python3 test/awgn_ber_analysis.py
python3 test/monte_carlo_analysis.py
python3 test/adaptive_throughput.py
```

The scripts produce numerical output and, where applicable, CSV files and PNG figures.

## Controller behavior

The implemented RTL controller uses the following rules:

- **Fast BPSK fallback:** Switch immediately to BPSK when an observation window contains 8 or more errors.
- **Stable QPSK recovery:** Require two consecutive windows containing at most 2 errors before returning from BPSK to QPSK.
- **Hysteresis region:** For 3–7 errors, retain the current modulation mode and cancel pending QPSK confirmation.

Each hardware observation window contains 128 valid bit comparisons.

## Interpretation

The Monte Carlo experiments evaluate the trade-off between modulation stability,
QPSK utilization and switching response.

For coherent BPSK and Gray-coded QPSK over AWGN, the theoretical bit error
probabilities are equal when compared at the same Eb/N0.

A measured BER of zero means that no errors were observed in the finite simulation;
it does not imply a zero theoretical error probability.

## Scope

These Python experiments are system-level numerical analyses.

They are separate from the synthesizable SystemVerilog RTL and do not constitute
a hardware-in-the-loop or gate-level AWGN simulation.

Hardware functionality is verified separately using Icarus Verilog, Cocotb,
Yosys and the Tiny Tapeout GDS workflow.
