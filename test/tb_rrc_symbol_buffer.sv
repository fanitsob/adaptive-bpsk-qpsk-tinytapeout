`timescale 1ns/1ps

module tb_rrc_symbol_buffer;

    logic clk = 0;
    logic rst_n = 0;

    logic mapper_valid = 0;
    logic mapper_i = 0;
    logic mapper_q = 0;
    logic mapper_mode = 0;

    logic scheduler_ready = 0;

    wire scheduler_valid;
    wire scheduler_i;
    wire scheduler_q;
    wire scheduler_mode;
    wire input_ready;
    wire overflow;

    always #10 clk = ~clk;

    rrc_symbol_buffer dut (
        .clk(clk),
        .rst_n(rst_n),

        .mapper_valid(mapper_valid),
        .mapper_i(mapper_i),
        .mapper_q(mapper_q),
        .mapper_mode(mapper_mode),

        .scheduler_ready(scheduler_ready),

        .scheduler_valid(scheduler_valid),
        .scheduler_i(scheduler_i),
        .scheduler_q(scheduler_q),
        .scheduler_mode(scheduler_mode),

        .input_ready(input_ready),
        .overflow(overflow)
    );

    initial begin

        repeat (3) @(negedge clk);
        rst_n = 1'b1;

        #1;

        if (input_ready !== 1'b1)
            $fatal(1, "Buffer must initially be ready");

        // Store one QPSK symbol.
        @(negedge clk);

        mapper_valid = 1'b1;
        mapper_i = 1'b1;
        mapper_q = 1'b0;
        mapper_mode = 1'b1;

        @(posedge clk);
        #1;

        if (scheduler_valid !== 1'b1)
            $fatal(1, "Symbol was not stored");

        if (scheduler_i !== 1'b1 ||
            scheduler_q !== 1'b0 ||
            scheduler_mode !== 1'b1)
            $fatal(1, "Stored symbol mismatch");

        $display("SYMBOL STORAGE TEST PASSED");

        // Keep the stored symbol while scheduler is busy.
        @(negedge clk);
        mapper_valid = 1'b0;

        repeat (3) @(posedge clk);
        #1;

        if (scheduler_valid !== 1'b1)
            $fatal(1, "Symbol lost while waiting");

        if (input_ready !== 1'b0)
            $fatal(1, "Full buffer incorrectly reports ready");

        $display("SYMBOL HOLD TEST PASSED");

        // Attempt to send another symbol while full.
        @(negedge clk);
        mapper_valid = 1'b1;
        mapper_i = 1'b0;
        mapper_q = 1'b1;
        mapper_mode = 1'b0;

        @(posedge clk);
        #1;

        if (overflow !== 1'b1)
            $fatal(1, "Overflow was not detected");

        if (scheduler_i !== 1'b1 ||
            scheduler_q !== 1'b0 ||
            scheduler_mode !== 1'b1)
            $fatal(1, "Stored symbol was overwritten");

        $display("OVERFLOW DETECTION TEST PASSED");

        // Scheduler accepts the original symbol.
        @(negedge clk);
        mapper_valid = 1'b0;
        scheduler_ready = 1'b1;

        @(posedge clk);
        #1;

        if (scheduler_valid !== 1'b0)
            $fatal(1, "Buffer did not empty");

        if (input_ready !== 1'b1)
            $fatal(1, "Buffer did not become ready");

        $display("SYMBOL HANDSHAKE TEST PASSED");
        $display("ALL RRC SYMBOL BUFFER TESTS PASSED");

        $finish;
    end

endmodule
