module rrc_stream_scheduler (
    input  logic              clk,
    input  logic              rst_n,

    input  logic              symbol_valid,
    input  logic              i_sign,
    input  logic              q_sign,
    input  logic              mode,

    output logic              symbol_ready,

    output logic signed [7:0] sample_out,
    output logic              sample_valid,
    output logic              sample_channel
);

    // 0 = I sample, 1 = Q sample
    // Four I/Q sample pairs per symbol.

    logic [2:0] cycle_count;
    logic running;
    logic primed;

    logic sample_tick;
    logic [1:0] phase;

    logic signed [7:0] i_sample;
    logic signed [7:0] q_sample;
    logic pair_valid;

    logic symbol_accept;

    // New symbol can enter every 8 clock cycles.
    assign symbol_ready = !running || (cycle_count == 3'd0);
    assign symbol_accept = symbol_valid && symbol_ready;

    // Compute one I/Q pair every two clock cycles.
    assign sample_tick = running && cycle_count[0];
    assign phase = cycle_count[2:1];

    rrc_iq_pair filters (
        .clk          (clk),
        .rst_n        (rst_n),

        .symbol_valid (symbol_accept),
        .i_sign       (i_sign),
        .q_sign       (q_sign),
        .mode         (mode),

        .sample_tick  (sample_tick),
        .phase        (phase),

        .i_sample     (i_sample),
        .q_sample     (q_sample),
        .sample_valid (pair_valid)
    );

    // Eight-cycle symbol schedule.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_count <= 3'd0;
            running     <= 1'b0;
            primed      <= 1'b0;
        end
        else begin
            if (!running) begin
                if (symbol_accept) begin
                    running     <= 1'b1;
                    cycle_count <= 3'd1;
                end
            end
            else begin
                cycle_count <= cycle_count + 3'd1;
            end

            // First filter output becomes available
            // after the first sample_tick.
            if (sample_tick)
                primed <= 1'b1;
        end
    end

    // Serialize I and Q onto the same 8-bit output.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_out     <= 8'sd0;
            sample_valid   <= 1'b0;
            sample_channel <= 1'b0;
        end
        else begin
            sample_valid <= running && primed;

            if (running && primed) begin
                if (cycle_count[0] == 1'b0) begin
                    sample_out     <= i_sample;
                    sample_channel <= 1'b0;
                end
                else begin
                    sample_out     <= q_sample;
                    sample_channel <= 1'b1;
                end
            end
        end
    end

    wire _unused = pair_valid;

endmodule
