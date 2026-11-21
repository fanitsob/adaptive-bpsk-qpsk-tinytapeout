`timescale 1ns/1ps

module tb_rrc_stream_scheduler;

    logic clk = 0;
    logic rst_n = 0;

    logic symbol_valid = 0;
    logic i_sign = 1;
    logic q_sign = 0;
    logic mode = 1;

    wire symbol_ready;
    wire signed [7:0] sample_out;
    wire sample_valid;
    wire sample_channel;

    integer expected_i [0:3];
    integer expected_q [0:3];

    integer count;
    integer timeout;

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

    initial begin

        expected_i[0] = -2;
        expected_i[1] = -1;
        expected_i[2] =  2;
        expected_i[3] =  5;

        expected_q[0] =  2;
        expected_q[1] =  1;
        expected_q[2] = -2;
        expected_q[3] = -5;

        repeat (3) @(negedge clk);
        rst_n = 1;

        // Send one QPSK symbol: I=+1, Q=-1.
        @(negedge clk);

        if (symbol_ready !== 1'b1)
            $fatal(1, "Scheduler not ready after reset");

        symbol_valid = 1;

        @(negedge clk);
        symbol_valid = 0;

        count = 0;
        timeout = 0;

        // Check four consecutive I/Q sample pairs.
        while (count < 8 && timeout < 30) begin

            @(negedge clk);
            timeout = timeout + 1;

            if (sample_valid) begin

                if (sample_channel !== (count % 2))
                    $fatal(1,
                        "Channel order failed at sample %0d",
                        count
                    );

                if ((count % 2) == 0) begin

                    if ($signed(sample_out) !== expected_i[count/2])
                        $fatal(1,
                            "I sample %0d: expected=%0d actual=%0d",
                            count/2,
                            expected_i[count/2],
                            $signed(sample_out)
                        );

                end
                else begin

                    if ($signed(sample_out) !== expected_q[count/2])
                        $fatal(1,
                            "Q sample %0d: expected=%0d actual=%0d",
                            count/2,
                            expected_q[count/2],
                            $signed(sample_out)
                        );

                end

                count = count + 1;
            end
        end

        if (count != 8)
            $fatal(1, "Scheduler timeout");

        $display("RRC SAMPLE ORDER TEST PASSED");
        $display("RRC I/Q SERIALIZATION TEST PASSED");
        $display("ALL RRC SCHEDULER TESTS PASSED");

        $finish;
    end

endmodule

