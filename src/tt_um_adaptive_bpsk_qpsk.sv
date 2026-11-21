`default_nettype none

module tt_um_adaptive_bpsk_qpsk (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,

    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,

    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    wire i_sign;
    wire q_sign;
    wire valid_out;

    wire mode;
    wire [7:0] error_count;
    wire window_done;
    wire error_detected;

    adaptive_bpsk_qpsk_core core (
        .clk            (clk),
        .rst_n          (rst_n),

        .data_in        (ui_in[1:0]),
        .valid_in       (ui_in[4]),

        .reference_bit  (ui_in[2]),
        .received_bit   (ui_in[3]),
        .compare_valid  (ui_in[5]),
        .clear_errors   (ui_in[6]),

        .i_sign         (i_sign),
        .q_sign         (q_sign),
        .valid_out      (valid_out),

        .mode           (mode),
        .error_count    (error_count),
        .window_done    (window_done),
        .error_detected (error_detected)
    );

    // Dedicated outputs
    assign uo_out = {
        2'b00,
        window_done,
        error_detected,
        mode,
        valid_out,
        q_sign,
        i_sign
    };

    // Error counter through bidirectional pins
    assign uio_out = error_count;

    // Configure all bidirectional pins as outputs
    assign uio_oe = 8'hFF;

    wire _unused = &{ena, ui_in[7], uio_in, 1'b0};

endmodule

`default_nettype wire
