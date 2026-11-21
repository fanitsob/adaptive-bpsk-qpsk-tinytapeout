<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

# Adaptive BPSK/QPSK Symbol Mapper with Error Monitoring

## How it works

This project implements a digital adaptive BPSK/QPSK symbol mapper
with an integrated error monitor and modulation controller.

The design consists of three main functional blocks:

1. BPSK/QPSK Symbol Mapper
2. Error Monitor
3. Adaptive Modulation Controller

### BPSK/QPSK Symbol Mapper

The symbol mapper converts incoming data bits into digital
in-phase (I) and quadrature (Q) sign outputs.

In BPSK mode, one input bit determines the I sign, while
the Q sign is held at zero.

In QPSK mode, two input bits determine the I and Q signs.

The mapper provides a valid output indicating when a
new symbol has been processed.

### Error Monitor

The error monitor compares a reference bit with a received bit
whenever compare_valid is asserted.

It counts bit mismatches over observation windows of
128 valid comparisons.

At the end of each window, the monitor updates the
8-bit error count and generates a window_done pulse.

The error count is used to evaluate the quality of the
observed digital bitstream.

### Adaptive Modulation Controller

The controller automatically selects BPSK or QPSK
according to the number of errors detected in each window.

The improved control strategy is:

- 0 to 2 errors: two consecutive low-error windows are
  required before switching from BPSK to QPSK.
- 3 to 7 errors: retain the current modulation mode and
  cancel any pending low-error confirmation.
- 8 or more errors: immediately select BPSK.

After reset, the controller starts in BPSK mode.

This strategy reduces unnecessary modulation-mode
switching while retaining a fast response to high error counts.

The circuit operates synchronously with the input clock
and uses an active-low reset.

The error monitor requires externally supplied, aligned
reference and received bitstreams. It does not contain
an RF receiver or an analog channel estimator.

## How to test

Apply a clock to the clk input and reset the circuit
using rst_n.

The digital input assignments are:

- ui_in[1:0]: Data bits for the symbol mapper
- ui_in[2]: Reference bit
- ui_in[3]: Received bit
- ui_in[4]: Symbol valid input
- ui_in[5]: Comparison valid input
- ui_in[6]: Clear error monitor

The output assignments are:

- uo_out[0]: I sign
- uo_out[1]: Q sign
- uo_out[2]: Symbol valid output
- uo_out[3]: Current modulation mode (0=BPSK, 1=QPSK)
- uo_out[4]: Error detected
- uo_out[5]: Observation window complete
- uio_out[7:0]: Error count

All eight uio pins are configured as outputs.

To test adaptive switching:

1. Reset the circuit. The initial mode is BPSK.
2. Supply 128 valid comparisons with no more than
   two bit errors.
3. Supply a second consecutive low-error window.
   The controller switches to QPSK.
4. Supply a window containing at least eight errors.
   The controller returns to BPSK.
5. Supply an intermediate-error window between two
   low-error windows to verify that the pending
   confirmation is cancelled.

The design includes SystemVerilog and Cocotb testbenches
for functional verification.

## External hardware

No external hardware is required for digital simulation.

For a physical demonstration, an external digital source
must provide the data, reference, and received bitstreams.

The I and Q outputs represent digital symbol signs;
external signal-generation hardware would be needed
for analog RF transmission.
