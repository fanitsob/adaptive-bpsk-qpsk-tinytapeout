`timescale 1ns/1ps

module tb_error_monitor;

    logic clk = 0;
    logic rst_n = 0;
    logic clear = 0;
    logic compare_valid = 0;
    logic reference_bit = 0;
    logic received_bit = 0;

    wire [7:0] error_count;
    wire window_done;
    wire error_detected;

    always #10 clk = ~clk;

    error_monitor dut (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),
        .compare_valid(compare_valid),
        .reference_bit(reference_bit),
        .received_bit(received_bit),
        .error_count(error_count),
        .window_done(window_done),
        .error_detected(error_detected)
    );

    initial begin
        repeat (3) @(negedge clk);
        rst_n = 1;

        // First window: 128 bits, exactly 8 errors
        for (int i = 0; i < 128; i++) begin
            @(negedge clk);
            compare_valid = 1;
            reference_bit = i % 2;
            received_bit = reference_bit ^ (i < 8);

            @(posedge clk);
            #1;

            if (i == 127) begin
                if (!window_done || error_count !== 8)
                    $fatal(1, "TEST 1 FAILED");
            end
            else if (window_done)
                $fatal(1, "Window finished too early");
        end

        // Pause: invalid cycles must not be counted
        @(negedge clk);
        compare_valid = 0;
        repeat (3) @(posedge clk);
        #1;

        if (window_done || error_count !== 8)
            $fatal(1, "PAUSE TEST FAILED");

        // Second window: 128 bits, exactly 2 errors
        for (int i = 0; i < 128; i++) begin
            @(negedge clk);
            compare_valid = 1;
            reference_bit = i % 2;
            received_bit = reference_bit ^ (i < 2);

            @(posedge clk);
            #1;

            if (i == 127) begin
                if (!window_done || error_count !== 2)
                    $fatal(1, "TEST 2 FAILED");
            end
            else if (window_done)
                $fatal(1, "Window finished too early");
        end

        @(negedge clk);
        compare_valid = 0;
        clear = 1;

        @(posedge clk);
        #1;

        if (error_count !== 0 || window_done !== 0)
            $fatal(1, "CLEAR TEST FAILED");

        $display("ALL ERROR MONITOR TESTS PASSED");
        $finish;
    end

endmodule

