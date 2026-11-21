module adaptive_controller (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [7:0] error_count,
    input  logic       window_done,

    output logic       mode
);

    // mode = 0: BPSK
    // mode = 1: QPSK

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mode <= 1'b0;
        end
        else if (window_done) begin

            if (error_count <= 8'd2) begin
                mode <= 1'b1;
            end

            else if (error_count >= 8'd8) begin
                mode <= 1'b0;
            end

            // Between 3 and 7 errors:
            // keep the previous modulation mode
        end
    end

endmodule
