`timescale 1ns/1ps

module tb_rrc_continuous;

    logic clk = 0;
    logic rst_n = 0;

    logic symbol_valid = 0;
    logic i_sign = 0;
    logic q_sign = 0;
    logic mode = 0;

    wire symbol_ready;

    wire signed [7:0] sample_out;
    wire sample_valid;
    wire sample_channel;

    integer h [0:24];
    integer sample_count = 0;
    integer expected_value;

    always #10 clk = ~clk;

    rrc_stream_scheduler dut (
        .clk(clk),
        .rst_n(rst_n),

        .symbol_valid(symbol_valid),
        .i_sign(i_sign),
        .q_sign(q_sign),
        .mode(mode),

        .symbol_ready(symbol_ready),

        .sample_out(sample_out),
        .sample_valid(sample_valid),
        .sample_channel(sample_channel)
    );

    // RRC coefficient lookup for the reference model.
    function automatic integer coeff(input integer index);
        begin
            if (index < 0 || index >= 25)
                coeff = 0;
            else
                coeff = h[index];
        end
    endfunction

    // Send one symbol only when the scheduler is ready.
    task automatic send_symbol(input logic sign_value);
        begin
            @(negedge clk);

            while (symbol_ready !== 1'b1)
                @(negedge clk);

            i_sign = sign_value;
            q_sign = 1'b0;
            mode = 1'b0;
            symbol_valid = 1'b1;

            @(negedge clk);
            symbol_valid = 1'b0;
        end
    endtask

    initial begin

        h[0]  = -2;
        h[1]  = -1;
        h[2]  =  2;
        h[3]  =  5;
        h[4]  =  5;
        h[5]  = -2;
        h[6]  = -11;
        h[7]  = -16;
        h[8]  = -7;
        h[9]  = 17;
        h[10] = 50;
        h[11] = 79;
        h[12] = 91;
        h[13] = 79;
        h[14] = 50;
        h[15] = 17;
        h[16] = -7;
        h[17] = -16;
        h[18] = -11;
        h[19] = -2;
        h[20] = 5;
        h[21] = 5;
        h[22] = 2;
        h[23] = -1;
        h[24] = -2;

        repeat (3) @(negedge clk);
        rst_n = 1'b1;

        // Consecutive symbols: +1, -1, +1.
        send_symbol(1'b1);
        send_symbol(1'b0);
        send_symbol(1'b1);

    end

    // Check 12 consecutive I/Q sample pairs.
    initial begin

        wait (rst_n == 1'b1);

        while (sample_count < 24) begin

            @(negedge clk);

            if (sample_valid) begin

                if ((sample_count % 2) == 0) begin

                    expected_value =
                        coeff(sample_count / 2)
                        - coeff(sample_count / 2 - 4)
                        + coeff(sample_count / 2 - 8);

                    if (sample_channel !== 1'b0)
                        $fatal(1, "Expected I channel");

                    if ($signed(sample_out) !== expected_value)
                        $fatal(1,
                            "I sample %0d: expected=%0d actual=%0d",
                            sample_count / 2,
                            expected_value,
                            $signed(sample_out)
                        );

                end
                else begin

                    if (sample_channel !== 1'b1)
                        $fatal(1, "Expected Q channel");

                    if ($signed(sample_out) !== 0)
                        $fatal(1,
                            "Q sample should be zero, got %0d",
                            $signed(sample_out)
                        );

                end

                sample_count = sample_count + 1;
            end

        end

        $display("THREE-SYMBOL RRC CONVOLUTION TEST PASSED");
        $display("CONTINUOUS I/Q STREAM TEST PASSED");
        $display("ALL CONTINUOUS RRC TESTS PASSED");

        $finish;
    end

    // Prevent an infinite simulation if samples stop.
    initial begin
        #20000;
        $fatal(1, "Continuous RRC test timeout");
    end

endmodule
