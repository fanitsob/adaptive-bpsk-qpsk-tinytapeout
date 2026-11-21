module rrc_iq_pair (
    input  logic clk,
    input  logic rst_n,

    input  logic symbol_valid,   // real symbol accepted this cycle
    input  logic bubble,         // insert an all-zero symbol (gap / tail flush)

    input  logic i_sign,
    input  logic q_sign,
    input  logic mode,

    input  logic sample_tick,
    input  logic [1:0] phase,

    output logic signed [7:0] i_sample,
    output logic signed [7:0] q_sample,
    output logic sample_valid
);
    logic signed [1:0] i_symbol, q_symbol;
    logic i_valid, q_valid;

    always_comb begin
        if (bubble) begin
            i_symbol = 2'sd0;
            q_symbol = 2'sd0;
        end else begin
            i_symbol = i_sign ? 2'sd1 : -2'sd1;
            q_symbol = (mode == 1'b1) ? (q_sign ? 2'sd1 : -2'sd1) : 2'sd0;
        end
    end

    wire shift = symbol_valid | bubble;

    rrc_pulse_shaper rrc_i (.clk(clk), .rst_n(rst_n), .symbol_valid(shift), .symbol_in(i_symbol),
        .sample_tick(sample_tick), .phase(phase), .sample_out(i_sample), .sample_valid(i_valid));
    rrc_pulse_shaper rrc_q (.clk(clk), .rst_n(rst_n), .symbol_valid(shift), .symbol_in(q_symbol),
        .sample_tick(sample_tick), .phase(phase), .sample_out(q_sample), .sample_valid(q_valid));

    assign sample_valid = i_valid & q_valid;
endmodule
