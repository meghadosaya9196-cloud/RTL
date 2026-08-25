`include "PISO.sv"
module tb_piso_10bit;
reg clk;
reg rst;
reg [9:0] par_in;
reg load_en;
wire ser_out;
PISO dut(.*);
initial begin
clk = 0;
forever #5 clk = ~clk;
end
initial begin
rst = 1;
par_in = 10'b1010101010;
load_en = 0;
#10 rst = 0;
#10 load_en = 1;
#10 load_en = 0;
#100;
repeat (10) begin
par_in = {$random} % 2 == 0 ? 10'h101 : 10'h0A5;
#10 load_en = 1;
#10 load_en = 0;
#100;
end
#1000 $finish;
end
  initial begin
$dumpfile("piso.vcd");
$dumpvars(2, tb_piso_10bit);
end
endmodule
