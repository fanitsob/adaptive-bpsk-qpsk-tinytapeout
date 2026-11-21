`timescale 1ns/1ps
module tb_f;
  logic clk=0, rst_n=0, ena=1; logic [7:0] ui_in=0, uio_in=0;
  wire [7:0] uo_out, uio_out, uio_oe;
  always #10 clk=~clk;
  tt_um_adaptive_bpsk_qpsk dut(.ui_in(ui_in),.uo_out(uo_out),.uio_in(uio_in),.uio_out(uio_out),.uio_oe(uio_oe),.ena(ena),.clk(clk),.rst_n(rst_n));
  integer sent=0; reg [1:0] d;
  initial begin
    repeat(3) @(negedge clk); rst_n=1; $display("BURST 0");
    while (sent<60) begin
      @(negedge clk);
      if (uo_out[4]) begin d=$urandom; ui_in={4'b1001,2'b00,d}; sent=sent+1; $display("SYM %0d %0d", d[1]?0:1, d[0]?0:1); end
      else ui_in=8'b10000000;
    end
    @(negedge clk); ui_in=8'b10000000; repeat(150) @(negedge clk);
    $display("BURST 1"); $display("BURST 2"); $display("BURST 3");
    $display("OVF %0d", uo_out[5]); $finish;
  end
  always @(negedge clk) if (uo_out[6]) $display("S %0d %0d", uo_out[7], $signed(uio_out));
endmodule
