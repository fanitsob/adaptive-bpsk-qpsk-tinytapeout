module adaptive_bpsk_qpsk_core (
    input  logic       clk,
    input  logic       rst_n,

    input  logic [1:0] data_in,
    input  logic       valid_in,

    input  logic       reference_bit,
    input  logic       received_bit,
    input  logic       compare_valid,
    input  logic       clear_errors,

    output logic       i_sign,
    output logic       q_sign,
    output logic       valid_out,

    output logic       mode,
    output logic [7:0] error_count,
    output logic       window_done,
    output logic       error_detected
);

    // 1. Error monitoring
    error_monitor monitor (
        .clk            (clk),
        .rst_n          (rst_n),
        .clear          (clear_errors),
        .compare_valid  (compare_valid),
        .reference_bit  (reference_bit),
        .received_bit   (received_bit),
        .error_count    (error_count),
        .window_done    (window_done),
        .error_detected (error_detected)
    );

    // 2. Adaptive modulation selection
    adaptive_controller controller (
        .clk        (clk),
        .rst_n      (rst_n),
        .error_count(error_count),
        .window_done(window_done),
        .mode       (mode)
    );

    // 3. BPSK/QPSK symbol mapping
    bpsk_qpsk_core mapper (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),
        .mode      (mode),
        .data_in   (data_in),
        .i_sign    (i_sign),
        .q_sign    (q_sign),
        .valid_out (valid_out)
    );

endmodule
