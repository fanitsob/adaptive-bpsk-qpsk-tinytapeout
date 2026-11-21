<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

# Adaptive BPSK/QPSK Modulator with RRC Pulse Shaping

## How it works

This project implements a digital adaptive BPSK/QPSK symbol mapper
with an integrated error monitor and modulation controller.

The design consists of six main functional blocks:

1. BPSK/QPSK Symbol Mapper
2. Error Monitor
3. Adaptive Modulation Controller
4. Symbol Buffer
5. RRC Stream Scheduler
6. Dual-Channel RRC Pulse Shaping

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

### Root-Raised-Cosine Pulse Shaping

The design includes two digital Root-Raised-Cosine (RRC)
pulse-shaping filters, one for the in-phase (I) component
and one for the quadrature (Q) component.

Each filter uses:

- 25 fixed-point coefficients
- Roll-off factor: approximately 0.35
- Filter span: 6 symbols
- Oversampling factor: 4 samples per symbol
- Signed 8-bit output samples

The filters use a polyphase architecture with seven
symbol-history positions.

Input symbols have values of -1, 0, or +1.
Coefficient multiplication is therefore implemented
using addition, subtraction, or bypass operations.

This avoids general-purpose multipliers.

### Symbol Buffer and RRC Scheduler

A one-symbol buffer connects the registered BPSK/QPSK
mapper to the RRC stream scheduler.

The scheduler accepts a new symbol every eight
clock cycles during continuous operation.

It generates four RRC sample pairs per symbol.
Each pair consists of one I sample and one Q sample.

The samples are serialized onto a shared 8-bit
output bus.

At the configured 50 MHz clock, the nominal maximum
input rate is 6.25 million symbols per second,
provided that the source follows the required
symbol timing.

The buffer detects input overflow if symbols arrive
faster than they can be accepted.

### Legacy and RRC Operating Modes

The ui_in[7] input selects the output interface:

- ui_in[7] = 0: Legacy adaptive BPSK/QPSK operation.
- ui_in[7] = 1: RRC sample output operation.

In legacy mode, uio_out contains the 8-bit error count.

In RRC mode, uio_out contains signed 8-bit RRC samples.

The RRC status outputs are:

- uo_out[4]: Symbol buffer input-ready indication
- uo_out[5]: Sticky buffer overflow flag
- uo_out[6]: RRC sample valid
- uo_out[7]: RRC sample channel (0=I, 1=Q)

The input source must respect the symbol processing
rate to avoid overflow. The input-ready indication
describes the internal buffer; external input timing
must also account for the registered symbol mapper.

The RRC filters are digital baseband pulse shapers.
The chip does not contain an RF carrier generator,
digital-to-analog converter, or analog transmitter.

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
### Testing RRC Pulse Shaping

To test RRC operation:

1. Assert rst_n low to reset the design.
2. Release reset and set ui_in[7] = 1.
3. Supply a valid BPSK or QPSK symbol using ui_in[4].
4. Observe uo_out[6] to identify valid output samples.
5. Read the signed 8-bit sample from uio_out[7:0].
6. Use uo_out[7] to distinguish I and Q samples.

The RRC scheduler generates four I/Q sample pairs
per accepted symbol.

Successive symbols must respect the processing interval
of eight clock cycles.

The following SystemVerilog testbenches verify the
RRC implementation:

- tb_rrc_pulse_shaper.sv: Impulse response and convolution
- tb_rrc_iq_pair.sv: BPSK/QPSK I/Q filtering
- tb_rrc_stream_scheduler.sv: Sample timing and serialization
- tb_rrc_continuous.sv: Consecutive-symbol convolution
- tb_rrc_symbol_buffer.sv: Buffering and overflow detection
- tb_rrc_top.sv: Top-level BPSK RRC operation
- tb_rrc_qpsk_top.sv: Adaptive QPSK RRC operation
- tb_rrc_overflow_top.sv: Top-level overflow detection
The design includes SystemVerilog and Cocotb testbenches
for functional verification.

## External hardware

No external hardware is required for digital simulation.

For a physical demonstration, an external digital source
must provide the data, reference, and received bitstreams.

The I and Q outputs represent digital symbol signs;
external signal-generation hardware would be needed
for analog RF transmission.
