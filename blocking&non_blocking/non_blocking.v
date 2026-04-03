`timescale 1ns/1ps
module non_blocking(
  input clk,
  input b,
  output reg a,
  output reg c);
  
  always @(posedge clk) begin
    a<=b;
    c<=a;
  end
  
endmodule
