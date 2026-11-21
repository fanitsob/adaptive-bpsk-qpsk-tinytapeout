// Two-entry symbol buffer. input_ready accounts for the symbol that is
// already in flight in the registered mapper (mapper_valid), so a source that
// only sends while input_ready=1 can never overflow.
module rrc_symbol_buffer (
    input  logic clk,
    input  logic rst_n,

    input  logic mapper_valid,
    input  logic mapper_i,
    input  logic mapper_q,
    input  logic mapper_mode,

    input  logic scheduler_ready,

    output logic scheduler_valid,
    output logic scheduler_i,
    output logic scheduler_q,
    output logic scheduler_mode,

    output logic input_ready,
    output logic overflow
);
    logic v0, v1;                 // entry 0 = head (to scheduler), entry 1 = skid
    logic i1, q1, m1;

    assign scheduler_valid = v0;

    wire pop  = v0 && scheduler_ready;
    wire full = v0 && v1;
    // conservative: count the in-flight mapper symbol, ignore this cycle's pop
    assign input_ready = ({1'b0, v0} + {1'b0, v1} + {1'b0, mapper_valid}) < 2'd2;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v0 <= 1'b0; v1 <= 1'b0; overflow <= 1'b0;
            scheduler_i <= 1'b0; scheduler_q <= 1'b0; scheduler_mode <= 1'b0;
            i1 <= 1'b0; q1 <= 1'b0; m1 <= 1'b0;
        end else begin
            if (pop) begin
                if (v1) begin
                    v0 <= 1'b1; scheduler_i <= i1; scheduler_q <= q1; scheduler_mode <= m1;
                    v1 <= 1'b0;
                end else
                    v0 <= 1'b0;
            end

            if (mapper_valid) begin
                if (!full || pop) begin
                    if (pop ? !v1 : !v0) begin       // head empty after this cycle's pop
                        v0 <= 1'b1;
                        scheduler_i <= mapper_i; scheduler_q <= mapper_q; scheduler_mode <= mapper_mode;
                    end else begin
                        v1 <= 1'b1; i1 <= mapper_i; q1 <= mapper_q; m1 <= mapper_mode;
                    end
                end else
                    overflow <= 1'b1;
            end
        end
    end
endmodule
