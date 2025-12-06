`timescale 1ns/1ns
module tb_Mux;
  reg I0,I1,I2,I3;
  reg [1:0]sel;
  wire Y;
  
  Mux dut(.I0(I0),.I1(I1),.I2(I2),.sel(sel),.Y(Y));
  
  initial begin
    $dumpfile("mux.vcd");
    $dumpvars(0,tb_Mux);
    I0=0;I1=1;I2=0;I3=1;
  
    sel=2'b00;#10;
  	sel=2'b01;#10;
  	sel=2'b10;#10;
  	sel=2'b11;#10;
  	$finish;
  end
endmodule 
  
