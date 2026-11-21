module error_monitor (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       clear,
    input  logic       compare_valid,
    input  logic       reference_bit,
    input  logic       received_bit,

    output logic [7:0] error_count,
    output logic       window_done,
    output logic       error_detected
);

    logic [6:0] sample_count;
    logic [7:0] current_errors;

    logic bit_error;

    assign bit_error = reference_bit ^ received_bit;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_count   <= 7'd0;
            current_errors <= 8'd0;
            error_count    <= 8'd0;
            window_done    <= 1'b0;
            error_detected <= 1'b0;
        end
        else if (clear) begin
            sample_count   <= 7'd0;
            current_errors <= 8'd0;
            error_count    <= 8'd0;
            window_done    <= 1'b0;
            error_detected <= 1'b0;
        end
        else begin
            window_done    <= 1'b0;
            error_detected <= 1'b0;

            if (compare_valid) begin

                error_detected <= bit_error;

                if (sample_count == 7'd127) begin
                    error_count <= current_errors
                                   + {7'd0, bit_error};

                    current_errors <= 8'd0;
                    sample_count   <= 7'd0;
                    window_done    <= 1'b1;
                end
                else begin
                    current_errors <= current_errors
                                      + {7'd0, bit_error};

                    sample_count <= sample_count + 1'b1;
                end
            end
        end
    end

endmodule

