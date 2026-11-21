module rrc_pulse_shaper (
    input  logic              clk,
    input  logic              rst_n,

    input  logic              symbol_valid,
    input  logic signed [1:0] symbol_in,

    input  logic              sample_tick,
    input  logic [1:0]        phase,

    output logic signed [7:0] sample_out,
    output logic              sample_valid
);

    // Symbol encoding:
    //  2'b01 = +1
    //  2'b00 =  0
    //  2'b11 = -1

    logic signed [1:0] history [0:6];

    logic signed [15:0] accumulator;

    integer i;

    // 25-tap RRC filter
    // beta = 0.35
    // 4 samples/symbol
    // span = 6 symbols
    //
    // Coefficients are quantized and scaled to
    // fit a signed 8-bit output.

    function automatic signed [7:0] coefficient(
        input integer index
    );
        begin
            case (index)
                 0: coefficient = -8'sd2;
                 1: coefficient = -8'sd1;
                 2: coefficient =  8'sd2;
                 3: coefficient =  8'sd5;
                 4: coefficient =  8'sd5;
                 5: coefficient = -8'sd2;
                 6: coefficient = -8'sd11;
                 7: coefficient = -8'sd16;
                 8: coefficient = -8'sd7;
                 9: coefficient =  8'sd17;
                10: coefficient =  8'sd50;
                11: coefficient =  8'sd79;
                12: coefficient =  8'sd91;
                13: coefficient =  8'sd79;
                14: coefficient =  8'sd50;
                15: coefficient =  8'sd17;
                16: coefficient = -8'sd7;
                17: coefficient = -8'sd16;
                18: coefficient = -8'sd11;
                19: coefficient = -8'sd2;
                20: coefficient =  8'sd5;
                21: coefficient =  8'sd5;
                22: coefficient =  8'sd2;
                23: coefficient = -8'sd1;
                24: coefficient = -8'sd2;

                default: coefficient = 8'sd0;
            endcase
        end
    endfunction

    // Polyphase convolution:
    // Each phase uses up to 7 coefficients.
    // Multiplication by -1, 0, +1 is implemented
    // as subtraction, bypass or addition.

    always_comb begin
        accumulator = 16'sd0;

        for (integer k = 0; k < 7; k = k + 1) begin

            if ((4*k + int'(phase)) < 25) begin
                case (history[k])
                    2'sd1:
                        accumulator = accumulator
                                   + 16'(coefficient(4*k + int'(phase)));

                    -2'sd1:
                        accumulator = accumulator
                                    - 16'(coefficient(4*k + int'(phase)));

                    default: begin
                        // Zero symbol contributes nothing.
                    end
                endcase

            end
        end
    end

    // Symbol history register

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 7; i = i + 1)
                history[i] <= 2'sd0;
        end
        else if (symbol_valid) begin

            history[0] <= symbol_in;

            for (i = 1; i < 7; i = i + 1)
                history[i] <= history[i-1];

        end
    end

    // Registered output

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_out   <= 8'sd0;
            sample_valid <= 1'b0;
        end
        else begin
            sample_valid <= sample_tick;

            if (sample_tick)
                sample_out <= accumulator[7:0];
        end
    end

endmodule
