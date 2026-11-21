module adaptive_controller (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [7:0] error_count,
    input  logic       window_done,

    output logic       mode
);

    // mode = 0: BPSK
    // mode = 1: QPSK

    // Tracks whether the previous completed window
    // also had 2 or fewer errors.
    logic low_error_pending;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mode              <= 1'b0;
            low_error_pending <= 1'b0;
        end
        else if (window_done) begin

            // Poor channel: immediately select BPSK.
            if (error_count >= 8'd8) begin
                mode              <= 1'b0;
                low_error_pending <= 1'b0;
            end

            // Good channel: require two consecutive
            // low-error windows before selecting QPSK.
            else if (error_count <= 8'd2) begin

                if (mode == 1'b0) begin
                    if (low_error_pending) begin
                        mode              <= 1'b1;
                        low_error_pending <= 1'b0;
                    end
                    else begin
                        low_error_pending <= 1'b1;
                    end
                end
                else begin
                    low_error_pending <= 1'b0;
                end
            end
            // Intermediate channel:
            // keep current mode and cancel confirmation.
            else begin
                low_error_pending <= 1'b0;
            end
        end
    end


endmodule
