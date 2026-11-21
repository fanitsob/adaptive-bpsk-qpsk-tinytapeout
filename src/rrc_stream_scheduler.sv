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
    localparam logic [2:0] TAIL_SLOTS = 3'd6;  // slots needed to flush a 7-deep history

    logic [2:0] cycle_count;
    logic       running, primed, stop;
    logic [2:0] tail_cnt;                      // zero slots still owed after the last real symbol

    logic       sample_tick;
    logic [1:0] phase;
    logic signed [7:0] i_sample, q_sample;
    logic       pair_valid;

    wire slot_start     = running && (cycle_count == 3'd0);
    assign symbol_ready = !running || slot_start;
    wire symbol_accept  = symbol_valid && symbol_ready;
    // empty slot while the filter still holds non-zero history -> shift in a zero symbol
    wire bubble         = slot_start && !symbol_valid && (tail_cnt != 3'd0);

    assign sample_tick = running && cycle_count[0];
    assign phase       = cycle_count[2:1];

    rrc_iq_pair filters (
        .clk(clk), .rst_n(rst_n),
        .symbol_valid(symbol_accept), .bubble(bubble),
        .i_sign(i_sign), .q_sign(q_sign), .mode(mode),
        .sample_tick(sample_tick), .phase(phase),
        .i_sample(i_sample), .q_sample(q_sample), .sample_valid(pair_valid)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_count <= 3'd0; running <= 1'b0; primed <= 1'b0;
            stop <= 1'b0; tail_cnt <= 3'd0;
        end else begin
            if (!running) begin
                if (symbol_accept) begin
                    running <= 1'b1; cycle_count <= 3'd1; tail_cnt <= TAIL_SLOTS; primed <= 1'b0;
                end
            end else begin
                cycle_count <= cycle_count + 3'd1;

                if (slot_start) begin
                    if (symbol_accept)          tail_cnt <= TAIL_SLOTS;
                    else if (tail_cnt != 3'd0)  tail_cnt <= tail_cnt - 3'd1;
                    else                        stop <= 1'b1;   // fully flushed: stop after draining
                end

                // let the last Q sample of the final slot leave the serializer, then idle
                if (stop) begin
                    running <= 1'b0; stop <= 1'b0; cycle_count <= 3'd0;
                end
            end
            if (sample_tick) primed <= 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_out <= 8'sd0; sample_valid <= 1'b0; sample_channel <= 1'b0;
        end else begin
            sample_valid <= running && primed;
            if (running && primed) begin
                if (cycle_count[0] == 1'b0) begin sample_out <= i_sample; sample_channel <= 1'b0; end
                else                        begin sample_out <= q_sample; sample_channel <= 1'b1; end
            end
        end
    end

    wire _unused = pair_valid;
endmodule
