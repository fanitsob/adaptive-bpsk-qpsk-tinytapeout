`timescale 1ns/1ps
module tb_d;
  logic clk=0, rst_n=0, ena=1; logic [7:0] ui_in=0, uio_in=0;
  wire [7:0] uo_out, uio_out, uio_oe;
  always #10 clk=~clk;
  tt_um_adaptive_bpsk_qpsk dut(.ui_in(ui_in),.uo_out(uo_out),.uio_in(uio_in),.uio_out(uio_out),.uio_oe(uio_oe),.ena(ena),.clk(clk),.rst_n(rst_n));
  integer n;
  initial begin
    repeat(3) @(negedge clk); rst_n=1;
    // legacy mode (ui[7]=0): 256 error-free compares, symbol valid EVERY cycle with data=00
    for(n=0;n<262;n=n+1) begin
      @(negedge clk);
      ui_in = (n<256) ? 8'b0011_0000 : 8'b0001_0000;   // valid + compare_valid(for first 256) , data=00
      if (n>=252) $display("n=%0d  mode(uo3)=%b  valid_out(uo2)=%b  q_sign(uo1)=%b  window_done(uo5)=%b", n, uo_out[3], uo_out[2], uo_out[1], uo_out[5]);
      if (n>=252 && uo_out[2] && (uo_out[3] !== uo_out[1])) $fatal(1, "B3 mode/sign mismatch");
    end
    $finish;
  end
endmodule
