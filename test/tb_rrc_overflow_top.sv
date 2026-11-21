`timescale 1ns/1ps

module tb_rrc_overflow_top;

    logic clk = 0;
    logic rst_n = 0;
    logic ena = 1;

    logic [7:0] ui_in = 0;
    logic [7:0] uio_in = 0;

    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    always #10 clk = ~clk;

    tt_um_adaptive_bpsk_qpsk dut (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(ena),
        .clk(clk),
        .rst_n(rst_n)
    );

    initial begin

        repeat (3) @(negedge clk);
        rst_n = 1'b1;

        // RRC enabled, BPSK mode.
        // Send 12 consecutive valid symbols.
        for (integer n = 0; n < 12; n = n + 1) begin
            @(negedge clk);
            ui_in = 8'b10010000;
        end

        @(negedge clk);
        ui_in = 8'b10000000;

        repeat (3) @(posedge clk);
        #1;

        if (uo_out[5] !== 1'b1)
            $fatal(1, "Expected RRC buffer overflow");

        $display("RRC OVERFLOW DETECTION TEST PASSED");

        // Verify that overflow remains asserted.
        repeat (10) @(posedge clk);
        #1;

        if (uo_out[5] !== 1'b1)
            $fatal(1, "Overflow flag did not remain asserted");

        $display("RRC STICKY OVERFLOW TEST PASSED");
        $display("ALL TOP-LEVEL OVERFLOW TESTS PASSED");

        $finish;
    end

endmodule

