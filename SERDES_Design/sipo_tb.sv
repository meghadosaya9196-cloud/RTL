`include "SIPO.sv"
module tb_SIPO;
reg clk;
reg rst;
reg ser_in;
reg shift_en;
wire [9:0] par_out;
SIPO dut(.*);
initial begin
clk = 0;
forever #5 clk = ~clk;
end
initial begin
rst = 1;
ser_in = 0;
shift_en = 1;
#10 rst = 0;
#10 shift_en = 0;
  repeat (10) begin
#10 ser_in = 1;
#10 ser_in = 0;
end
#10 shift_en = 1;
#100;
repeat (9) begin
#10 shift_en = 0;
repeat (10) begin
#10 ser_in = $random;
end
#10 shift_en = 1;
#100;
  #50 $finish;
end
initial begin
$dumpfile("sipo.vcd");
$dumpvars(2, tb_SIPO);
end
endmodule

end
  
