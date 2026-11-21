module rrc_symbol_buffer (
    input  logic clk,
    input  logic rst_n,

    // Input from registered BPSK/QPSK mapper
    input  logic mapper_valid,
    input  logic mapper_i,
    input  logic mapper_q,
    input  logic mapper_mode,

    // RRC scheduler handshake
    input  logic scheduler_ready,

    output logic scheduler_valid,
    output logic scheduler_i,
    output logic scheduler_q,
    output logic scheduler_mode,

    output logic input_ready,
    output logic overflow
);

    logic pending;

    assign scheduler_valid = pending;

    // An existing symbol can be replaced when
    // the scheduler accepts it on the same clock.
    assign input_ready = !pending || scheduler_ready;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending        <= 1'b0;
            scheduler_i    <= 1'b0;
            scheduler_q    <= 1'b0;
            scheduler_mode <= 1'b0;
            overflow       <= 1'b0;
        end
        else begin

            if (pending && scheduler_ready)
                pending <= 1'b0;

            if (mapper_valid) begin

                if (input_ready) begin
                    scheduler_i    <= mapper_i;
                    scheduler_q    <= mapper_q;
                    scheduler_mode <= mapper_mode;
                    pending        <= 1'b1;
                end
                else begin
                    // Sticky overflow flag
                    overflow <= 1'b1;
                end

            end
        end
    end

endmodule
