#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."
build_dir=$(mktemp -d)

# B1: RRC gaps, bursts and tail flushing
iverilog -g2012 -s tb_e -o "$build_dir/bursts.vvp" src/*.sv test/rrc_regression/tb_e.sv

for mode in 0 1; do
    for k in 1 2 3; do
        vvp "$build_dir/bursts.vvp" "+K=$k" "+NSYM=12" "+QPSK=$mode" |
            python3 test/rrc_regression/chk2.py "$mode" "$k"
    done
done

# B2: Ready protocol and buffer overflow
iverilog -g2012 -s tb_f -o "$build_dir/buffer.vvp" src/*.sv test/rrc_regression/tb_f.sv

vvp "$build_dir/buffer.vvp" |
    python3 test/rrc_regression/chk3.py 0 1

# B3: Modulation mode alignment
iverilog -g2012 -s tb_d -o "$build_dir/mode.vvp" src/*.sv test/rrc_regression/tb_d.sv

vvp "$build_dir/mode.vvp"

echo "ALL RRC REGRESSION TESTS PASSED"
