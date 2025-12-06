`timescale 1ns/1ns
module tb_decoder_3to8;
  reg [2:0]i;
  wire [7:0]y;
  
  decoder_3to8 dut(.i(i),.y(y));
  
  initial begin
    $dumpfile("decoder.vcd");
    $dumpvars(0,tb_decoder_3to8);
    
    i=3'b000;#10;
    i=3'b001;#10;
    i=3'b010;#10;
    i=3'b011;#10;
    i=3'b100;#10;
    i=3'b101;#10;
    i=3'b110;#10;
    i=3'b111;#10;
    $finish;
  end
endmodule
  
