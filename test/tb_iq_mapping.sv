`timescale 1ns/1ps

module tb_iq_mapping;

    logic clk = 0;
    logic rst_n = 0;
    logic valid_in = 0;
    logic mode = 0;
    logic [1:0] data_in = 0;

    wire i_sign;
    wire q_sign;
    wire valid_out;

    always #10 clk = ~clk;

    bpsk_qpsk_core dut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .mode(mode),
        .data_in(data_in),
        .i_sign(i_sign),
        .q_sign(q_sign),
        .valid_out(valid_out)
    );

    initial begin

        repeat (3) @(negedge clk);
        rst_n = 1;

        // BPSK
        @(negedge clk);
        mode = 0;
        data_in = 2'b00;
        valid_in = 1;

        @(posedge clk);
        #1;

        if (i_sign !== 1 || q_sign !== 0 || valid_out !== 1)
            $fatal(1, "BPSK mapping failed");

        $display("BPSK I/Q MAPPING PASS");

        // QPSK
        @(negedge clk);
        mode = 1;
        data_in = 2'b00;

        @(posedge clk);
        #1;

        if (i_sign !== 1 || q_sign !== 1 || valid_out !== 1)
            $fatal(1, "QPSK mapping failed");

        $display("QPSK I/Q MAPPING PASS");

        $display("ALL I/Q MAPPING TESTS PASSED");
        $finish;

    end

endmodule
