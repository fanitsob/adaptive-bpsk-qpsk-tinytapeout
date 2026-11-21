`timescale 1ns/1ps
module tb_e;
  logic clk=0, rst_n=0, ena=1; logic [7:0] ui_in=0, uio_in=0;
  wire [7:0] uo_out, uio_out, uio_oe;
  always #10 clk=~clk;
  tt_um_adaptive_bpsk_qpsk dut(.ui_in(ui_in),.uo_out(uo_out),.uio_in(uio_in),.uio_out(uio_out),.uio_oe(uio_oe),.ena(ena),.clk(clk),.rst_n(rst_n));
  integer K, NSYM, QPSK, b, k;
  reg [1:0] d;
  initial begin
    if(!$value$plusargs("K=%d",K)) K=1;
    if(!$value$plusargs("NSYM=%d",NSYM)) NSYM=12;
    if(!$value$plusargs("QPSK=%d",QPSK)) QPSK=0;
    repeat(3) @(negedge clk); rst_n=1;
    if (QPSK) begin repeat(256) begin @(negedge clk); ui_in=8'b10100000; end @(negedge clk); ui_in=8'b10000000; repeat(6) @(negedge clk); end
    for (b=0;b<3;b=b+1) begin
      $display("BURST %0d", b);
      for(k=0;k<NSYM;k=k+1) begin
        d=$urandom;
        @(negedge clk); ui_in={4'b1001,2'b00,d};
        $display("SYM %0d %0d", d[1]?0:1, d[0]?0:1);
        @(negedge clk); ui_in=8'b10000000;
        repeat(8*K-2) @(negedge clk);
      end
      repeat(150) @(negedge clk);
    end
    $display("BURST 3");
    $display("OVF %0d", uo_out[5]);
    $finish;
  end
  always @(negedge clk) if (uo_out[6]) $display("S %0d %0d", uo_out[7], $signed(uio_out));
endmodule
