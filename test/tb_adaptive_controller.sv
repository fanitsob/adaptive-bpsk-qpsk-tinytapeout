`timescale 1ns/1ps

module tb_adaptive_controller;

    logic clk = 0;
    logic rst_n = 0;
    logic [7:0] error_count = 0;
    logic window_done = 0;

    wire mode;

    always #10 clk = ~clk;

    adaptive_controller dut (
        .clk(clk),
        .rst_n(rst_n),
        .error_count(error_count),
        .window_done(window_done),
        .mode(mode)
    );

    task automatic check_mode(
        input logic [7:0] errors,
        input logic expected_mode
    );
        begin
            @(negedge clk);
            error_count = errors;
            window_done = 1;

            @(posedge clk);
            #1;

            if (mode !== expected_mode) begin
                $fatal(1,
                    "FAILED: errors=%0d expected=%0b actual=%0b",
                    errors, expected_mode, mode
                );
            end

            @(negedge clk);
            window_done = 0;
        end
    endtask

    initial begin

        // Reset
        repeat (3) @(negedge clk);
        rst_n = 1;

        #1;

        if (mode !== 0)
            $fatal(1, "Reset failed");

        // 2 errors: switch to QPSK
        check_mode(8'd2, 1'b1);

        // 5 errors: remain in QPSK
        check_mode(8'd5, 1'b1);

        // 8 errors: switch to BPSK
        check_mode(8'd8, 1'b0);

        // 5 errors: remain in BPSK
        check_mode(8'd5, 1'b0);

        // 1 error: switch to QPSK
        check_mode(8'd1, 1'b1);

        $display("ALL ADAPTIVE CONTROLLER TESTS PASSED");

        $finish;
    end

endmodule
