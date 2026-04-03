`timescale 1ns/1ps
module tb_blocking;
  
  reg clk;
  reg a;
  wire b;
  wire c;
  
  blocking ut(.clk(clk),.b(b),.a(a),.c(c));
  
  //clock generation
  
  initial begin
    clk=0;
    forever #5 clk=~clk;
  end
  
  //stimulus
  
  initial begin
    a=0;
    #12 a=1;
    #10 a=0;
    #10 a=1;
    #20 $finish;
  end
endmodule
