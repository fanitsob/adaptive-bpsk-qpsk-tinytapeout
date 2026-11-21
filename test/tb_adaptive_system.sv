`timescale 1ns/1ps

module tb_adaptive_system;

    logic clk = 0;
    logic rst_n = 0;

    logic [1:0] data_in = 0;
    logic valid_in = 0;

    logic reference_bit = 0;
    logic received_bit = 0;
    logic compare_valid = 0;
    logic clear_errors = 0;

    wire i_sign;
    wire q_sign;
    wire valid_out;
    wire mode;
    wire [7:0] error_count;
    wire window_done;
    wire error_detected;

    always #10 clk = ~clk;

    adaptive_bpsk_qpsk_core dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .valid_in(valid_in),
        .reference_bit(reference_bit),
        .received_bit(received_bit),
        .compare_valid(compare_valid),
        .clear_errors(clear_errors),
        .i_sign(i_sign),
        .q_sign(q_sign),
        .valid_out(valid_out),
        .mode(mode),
        .error_count(error_count),
        .window_done(window_done),
        .error_detected(error_detected)
    );

    task automatic send_window(
        input integer errors,
        input logic expected_mode
    );
        begin
            for (int i = 0; i < 128; i++) begin
                @(negedge clk);
                compare_valid = 1;
                reference_bit = i % 2;
                received_bit = reference_bit ^ (i < errors);
            end

            @(negedge clk);
            compare_valid = 0;

            // Allow controller to process completed window
            repeat (2) @(posedge clk);
            #1;

            if (error_count !== errors)
                $fatal(1, "Error count mismatch");

            if (mode !== expected_mode)
                $fatal(1, "Adaptive mode mismatch");

            $display(
                "Errors=%0d Mode=%s PASS",
                errors,
                mode ? "QPSK" : "BPSK"
            );
        end
    endtask

    initial begin

        repeat (3) @(negedge clk);
        rst_n = 1;

        #1;

        if (mode !== 0)
            $fatal(1, "Reset mode must be BPSK");

        // No errors: QPSK
        send_window(0, 1'b1);

        // Intermediate errors: remain QPSK
        send_window(5, 1'b1);

        // Many errors: switch to BPSK
        send_window(12, 1'b0);

        $display("ALL ADAPTIVE SYSTEM TESTS PASSED");
        $finish;
    end

endmodule
