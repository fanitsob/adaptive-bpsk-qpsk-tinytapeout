`timescale 1ns/1ps

module tb_rrc_qpsk_top;

    logic clk = 0;
    logic rst_n = 0;
    logic ena = 1;

    logic [7:0] ui_in = 0;
    logic [7:0] uio_in = 0;

    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    integer expected [0:3];
    integer count = 0;
    integer timeout = 0;
    integer actual;

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
        expected[0] = -2;
        expected[1] = -1;
        expected[2] =  2;
        expected[3] =  5;

        repeat (3) @(negedge clk);
        rst_n = 1'b1;

        // RRC enabled, 256 valid comparisons with no errors.
        // This completes two low-error observation windows.
        for (integer n = 0; n < 256; n = n + 1) begin
            @(negedge clk);
            ui_in = 8'b10100000;
        end

        @(negedge clk);
        ui_in = 8'b10000000;

        repeat (3) @(posedge clk);
        #1;

        if (uo_out[3] !== 1'b1)
            $fatal(1, "Controller did not select QPSK");

        $display("ADAPTIVE QPSK SELECTION TEST PASSED");

        // data_in = 01:
        // i_sign = 1 (+1), q_sign = 0 (-1).
        @(negedge clk);
        ui_in = 8'b10010001;

        @(negedge clk);
        ui_in = 8'b10000000;

        while (count < 8 && timeout < 40) begin
            @(negedge clk);
            timeout = timeout + 1;

            if (uo_out[6]) begin
                actual = $signed(uio_out);

                if ((count % 2) == 0) begin

                    if (uo_out[7] !== 1'b0)
                        $fatal(1, "Expected I channel");

                    if (actual !== expected[count/2])
                        $fatal(1,
                            "I sample %0d: expected=%0d actual=%0d",
                            count/2, expected[count/2], actual
                        );

                end
                else begin

                    if (uo_out[7] !== 1'b1)
                        $fatal(1, "Expected Q channel");

                    if (actual !== -expected[count/2])
                        $fatal(1,
                            "Q sample %0d: expected=%0d actual=%0d",
                            count/2, -expected[count/2], actual
                        );

                end

                count = count + 1;
            end
        end

        if (count != 8)
            $fatal(1, "QPSK RRC timeout");

        if (uo_out[5] !== 1'b0)
            $fatal(1, "Unexpected buffer overflow");

        $display("QPSK I/Q RRC SAMPLE TEST PASSED");
        $display("ALL TOP-LEVEL QPSK RRC TESTS PASSED");

        $finish;
    end

endmodule
