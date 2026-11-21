`timescale 1ns/1ps

module tb_rrc_pulse_shaper;

    logic clk = 0;
    logic rst_n = 0;

    logic symbol_valid = 0;
    logic signed [1:0] symbol_in = 0;

    logic sample_tick = 0;
    logic [1:0] phase = 0;

    wire signed [7:0] sample_out;
    wire sample_valid;

    integer expected [0:27];

    always #10 clk = ~clk;

    rrc_pulse_shaper dut (
        .clk(clk),
        .rst_n(rst_n),
        .symbol_valid(symbol_valid),
        .symbol_in(symbol_in),
        .sample_tick(sample_tick),
        .phase(phase),
        .sample_out(sample_out),
        .sample_valid(sample_valid)
    );

    task automatic push_symbol(input logic signed [1:0] value);
        begin
            @(negedge clk);
            symbol_in = value;
            symbol_valid = 1'b1;

            @(posedge clk);
            #1;

            @(negedge clk);
            symbol_valid = 1'b0;
        end
    endtask

    task automatic check_sample(
        input logic [1:0] sample_phase,
        input integer expected_value
    );
        begin
            @(negedge clk);
            phase = sample_phase;
            sample_tick = 1'b1;

            @(posedge clk);
            #1;

            if (sample_valid !== 1'b1)
                $fatal(1, "sample_valid missing");

            if ($signed(sample_out) !== expected_value)
                $fatal(1,
                    "RRC mismatch: phase=%0d expected=%0d actual=%0d",
                    sample_phase, expected_value, $signed(sample_out)
                );

            @(negedge clk);
            sample_tick = 1'b0;
        end
    endtask

initial begin

 
        // Expected impulse response:
        // 25 RRC coefficients followed by three zeros.

        expected[0]  = -2;
        expected[1]  = -1;
        expected[2]  =  2;
        expected[3]  =  5;
        expected[4]  =  5;
        expected[5]  = -2;
        expected[6]  = -11;
        expected[7]  = -16;
        expected[8]  = -7;
        expected[9]  = 17;
        expected[10] = 50;
        expected[11] = 79;
        expected[12] = 91;
        expected[13] = 79;
        expected[14] = 50;
        expected[15] = 17;
        expected[16] = -7;
        expected[17] = -16;
        expected[18] = -11;
        expected[19] = -2;
        expected[20] = 5;
        expected[21] = 5;
        expected[22] = 2;
        expected[23] = -1;
        expected[24] = -2;
        expected[25] = 0;
        expected[26] = 0;
        expected[27] = 0;

        repeat (3) @(negedge clk);
        rst_n = 1'b1;

        // Insert one positive impulse.
        push_symbol(2'sd1);

        for (integer n = 0; n < 28; n = n + 1) begin

            // Insert one zero symbol every four samples.
            if ((n > 0) && ((n % 4) == 0))
                push_symbol(2'sd0);

            check_sample(n % 4, expected[n]);
        end
        // Negative impulse response test

        push_symbol(-2'sd1);

        for (integer n = 0; n < 28; n = n + 1) begin

            if ((n > 0) && ((n % 4) == 0))
                push_symbol(2'sd0);

            check_sample(n % 4, -expected[n]);

        end


        // Multi-symbol convolution test
        // Sequence: +1, -1, +1, 0, 0, ...

        @(negedge clk);
        rst_n = 1'b0;

        repeat (3) @(negedge clk);
        rst_n = 1'b1;

        for (integer n = 0; n < 40; n = n + 1) begin

            if ((n % 4) == 0) begin

                case (n / 4)
                    0: push_symbol(2'sd1);
                    1: push_symbol(-2'sd1);
                    2: push_symbol(2'sd1);
                    default: push_symbol(2'sd0);
                endcase

            end

            begin : expected_convolution
                integer target;

                target = 0;

                if (n < 25)
                    target = target + expected[n];

                if ((n >= 4) && (n < 29))
                    target = target - expected[n-4];

                if ((n >= 8) && (n < 33))
                    target = target + expected[n-8];

                check_sample(n % 4, target);
            end

        end

        $display("MULTI-SYMBOL RRC CONVOLUTION TEST PASSED");
 $display("ALL RRC IMPULSE RESPONSE TESTS PASSED");

        $finish;
    end
endmodule
