`timescale 1ns/1ps

module tb_rrc_iq_pair;

    logic clk = 0;
    logic rst_n = 0;

    logic symbol_valid = 0;
    logic i_sign = 0;
    logic q_sign = 0;
    logic mode = 0;

    logic sample_tick = 0;
    logic [1:0] phase = 0;

    wire signed [7:0] i_sample;
    wire signed [7:0] q_sample;
    wire sample_valid;

    integer expected [0:3];

    always #10 clk = ~clk;

    rrc_iq_pair dut (
        .clk(clk),
        .rst_n(rst_n),

        .symbol_valid(symbol_valid),
        .i_sign(i_sign),
        .q_sign(q_sign),
        .mode(mode),

        .sample_tick(sample_tick),
        .phase(phase),

        .i_sample(i_sample),
        .q_sample(q_sample),
        .sample_valid(sample_valid)
    );

    task automatic reset_dut;
        begin
            @(negedge clk);
            rst_n = 0;

            repeat (3) @(negedge clk);
            rst_n = 1;
        end
    endtask

    task automatic push_iq_symbol(
        input logic new_mode,
        input logic new_i,
        input logic new_q
    );
        begin
            @(negedge clk);

            mode = new_mode;
            i_sign = new_i;
            q_sign = new_q;
            symbol_valid = 1;

            @(posedge clk);
            #1;

            @(negedge clk);
            symbol_valid = 0;
        end
    endtask

    task automatic check_iq(
        input logic [1:0] p,
        input integer expected_i,
        input integer expected_q
    );
        begin
            @(negedge clk);

            phase = p;
            sample_tick = 1;

            @(posedge clk);
            #1;

            if (sample_valid !== 1'b1)
                $fatal(1, "Missing sample_valid");

            if ($signed(i_sample) !== expected_i)
                $fatal(1,
                    "I mismatch: expected=%0d actual=%0d",
                    expected_i, $signed(i_sample)
                );

            if ($signed(q_sample) !== expected_q)
                $fatal(1,
                    "Q mismatch: expected=%0d actual=%0d",
                    expected_q, $signed(q_sample)
                );

            @(negedge clk);
            sample_tick = 0;
        end
    endtask

    initial begin

        expected[0] = -2;
        expected[1] = -1;
        expected[2] =  2;
        expected[3] =  5;

        // Test 1: BPSK
        // I = +1, Q = 0

        reset_dut();

        push_iq_symbol(1'b0, 1'b1, 1'b0);

        for (integer n = 0; n < 4; n = n + 1)
            check_iq(n % 4, expected[n], 0);

        $display("BPSK I/Q RRC TEST PASSED");

        // Test 2: QPSK
        // I = +1, Q = -1

        reset_dut();

        push_iq_symbol(1'b1, 1'b1, 1'b0);

        for (integer n = 0; n < 4; n = n + 1)
            check_iq(n % 4, expected[n], -expected[n]);

        $display("QPSK I/Q RRC TEST PASSED");

        $display("ALL I/Q RRC TESTS PASSED");
        $finish;

    end

endmodule

