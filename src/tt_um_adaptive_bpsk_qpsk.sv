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

    wire rrc_enable;
    assign rrc_enable = ui_in[7];

    // Keep the modulation mode aligned with
    // the registered mapper output.
    reg mapper_mode;
    reg mapper_rrc_enable;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mapper_mode       <= 1'b0;
            mapper_rrc_enable <= 1'b0;
        end
        else if (ui_in[4]) begin
            mapper_mode       <= mode;
            mapper_rrc_enable <= rrc_enable;
        end
    end

    // Existing adaptive modem.
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

    // Symbol buffer.
    wire scheduler_ready;
    wire scheduler_valid;

    wire scheduler_i;
    wire scheduler_q;
    wire scheduler_mode;

    wire buffer_ready;
    wire buffer_overflow;

    rrc_symbol_buffer symbol_buffer (
        .clk            (clk),
        .rst_n          (rst_n),

        .mapper_valid   (valid_out && mapper_rrc_enable),
        .mapper_i       (i_sign),
        .mapper_q       (q_sign),
        .mapper_mode    (mapper_mode),

        .scheduler_ready(scheduler_ready),

        .scheduler_valid(scheduler_valid),
        .scheduler_i    (scheduler_i),
        .scheduler_q    (scheduler_q),
        .scheduler_mode (scheduler_mode),

        .input_ready    (buffer_ready),
        .overflow       (buffer_overflow)
    );

    // RRC scheduler and I/Q pulse shaping.
    wire signed [7:0] rrc_sample;
    wire rrc_sample_valid;
    wire rrc_sample_channel;

    rrc_stream_scheduler rrc_scheduler (
        .clk           (clk),
        .rst_n         (rst_n),

        .symbol_valid  (scheduler_valid),
        .i_sign        (scheduler_i),
        .q_sign        (scheduler_q),
        .mode          (scheduler_mode),

        .symbol_ready  (scheduler_ready),

        .sample_out    (rrc_sample),
        .sample_valid  (rrc_sample_valid),
        .sample_channel(rrc_sample_channel)
    );

    // Legacy outputs remain unchanged when RRC is disabled.
    assign uo_out = {
        rrc_enable ? rrc_sample_channel : 1'b0,
        rrc_enable ? rrc_sample_valid   : 1'b0,
        rrc_enable ? buffer_overflow    : window_done,
        rrc_enable ? buffer_ready       : error_detected,
        mode,
        valid_out,
        q_sign,
        i_sign
    };

    // In RRC mode, output the signed 8-bit sample.
    // Otherwise, output the existing error counter.
    assign uio_out = rrc_enable ? rrc_sample : error_count;

    assign uio_oe = 8'hFF;

    wire _unused = &{ena, uio_in, 1'b0};

endmodule

`default_nettype wire
