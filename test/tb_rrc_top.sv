`timescale 1ns/1ps

module tb_rrc_top;

    logic clk = 0;
    logic rst_n = 0;

    logic [7:0] ui_in = 0;
    logic [7:0] uio_in = 0;
    logic ena = 1;

    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    integer expected [0:3];
    integer count = 0;
    integer timeout = 0;
    integer sample_value;

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

        // RRC enabled, BPSK mode after reset.
        // data_in = 00 -> I sign = +1.
        @(negedge clk);
        ui_in = 8'b10010000;

        @(negedge clk);
        ui_in = 8'b10000000;

        // Wait for four I/Q sample pairs.
        while (count < 8 && timeout < 40) begin

            @(negedge clk);
            timeout = timeout + 1;

            if (uo_out[6]) begin

                if (uio_oe !== 8'hFF)
                    $fatal(1, "Output direction mismatch");

                sample_value = $signed(uio_out);

                if ((count % 2) == 0) begin

                    if (uo_out[7] !== 1'b0)
                        $fatal(1, "Expected I sample");

                    if (sample_value !== expected[count/2])
                        $fatal(1,
                            "I sample %0d: expected=%0d actual=%0d",
                            count/2,
                            expected[count/2],
                            sample_value
                        );

                end
                else begin

                    if (uo_out[7] !== 1'b1)
                        $fatal(1, "Expected Q sample");

                    if (sample_value !== 0)
                        $fatal(1,
                            "Q sample should be zero, actual=%0d",
                            sample_value
                        );

                end

                count = count + 1;
            end
        end

        if (count != 8)
            $fatal(1, "RRC top-level timeout");

        if (uo_out[5] !== 1'b0)
            $fatal(1, "Unexpected buffer overflow");

        $display("TOP-LEVEL RRC SAMPLE TEST PASSED");
        $display("TOP-LEVEL RRC PIN MAPPING TEST PASSED");
        $display("ALL TOP-LEVEL RRC TESTS PASSED");

        $finish;
    end

endmodule

