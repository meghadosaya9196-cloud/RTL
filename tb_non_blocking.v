
`timescale 1ns/1ps
module tb_non_blocking;
  
  reg clk;
  reg b;
  wire a;
  wire c;
  
  non_blocking ut(.clk(clk),.b(b),.a(a),.c(c));
  
  //clock generation
  
  inital begin
        clk=0;
    forever #5 clk=~clk;
  end
  
  //stimulus
  
  inital begin
    b=0;
    #12 b=1;
    #10 b=0;
    #10 b=1;
    #20 $finish;
    
  end
  
  // monitor
  $monitor("time=%0t |b=%b a=%b c=%b",$time,b,a,c);
  end
  
endmodule
