`timescale 1ns/1ps
module tb_encoder;
logic clk;
logic rst;
logic [7:0] data_8b_in;
logic ser_en;
logic [9:0] data_10b_out;
// Instantiate the DUT (Device Under Test)
encoder dut (
.clk(clk),
.rst(rst),
.data_8b_in(data_8b_in),
.ser_en(ser_en),
.data_10b_out(data_10b_out)
);
// Clock generation (10ns period = 100MHz)
always #5 clk = ~clk;
// VCD dump - generates dump.vcd file for waveform viewing
initial begin
$dumpfile("encoder_dump.vcd");
$dumpvars(0, tb_encoder);
end
initial begin
// Initialize signals
  clk = 0;
rst = 1;
ser_en = 0;
data_8b_in = 8'h00;
// Reset sequence
#20 rst = 0;
// Test case 1: data = 8'h00
  #10 data_8b_in = 8'h00; ser_en = 1;
#10 ser_en = 0;
#10 $display("Input: 8'h%02h, Output: 10'h%03h", 8'h00, data_10b_out);
// Test case 2: data = 8'hFF
#10 data_8b_in = 8'hFF; ser_en = 1;
#10 ser_en = 0;
#10 $display("Input: 8'h%02h, Output: 10'h%03h", 8'hFF, data_10b_out);
// Test case 3: data = 8'h55
#10 data_8b_in = 8'h55; ser_en = 1;
#10 ser_en = 0;
#10 $display("Input: 8'h%02h, Output: 10'h%03h", 8'h55, data_10b_out);
// Test case 4: data = 8'hA5
#10 data_8b_in = 8'hA5; ser_en = 1;
#10 ser_en = 0;
#10 $display("Input: 8'h%02h, Output: 10'h%03h", 8'hA5, data_10b_out);
// Test case 5: data = 8'h0F
#10 data_8b_in = 8'h0F; ser_en = 1;
#10 ser_en = 0;
#10 $display("Input: 8'h%02h, Output: 10'h%03h", 8'h0F, data_10b_out);
// Test case 6: data = 8'hF0
#10 data_8b_in = 8'hF0; ser_en = 1;
#10 ser_en = 0;
#10 $display("Input: 8'h%02h, Output: 10'h%03h", 8'hF0, data_10b_out);
// Test case 7: data = 8'hAA
#10 data_8b_in = 8'hAA; ser_en = 1;
#10 ser_en = 0;
#10 $display("Input: 8'h%02h, Output: 10'h%03h", 8'hAA, data_10b_out);
// Test case 8: data = 8'h33
#10 data_8b_in = 8'h33; ser_en = 1;
#10 ser_en = 0;
#10 $display("Input: 8'h%02h, Output: 10'h%03h", 8'h33, data_10b_out);
// Test case 9: data = 8'h7E
#10 data_8b_in = 8'h7E; ser_en = 1;
#10 ser_en = 0;
#10 $display("Input: 8'h%02h, Output: 10'h%03h", 8'h7E, data_10b_out);
// Test case 10: data = 8'h81
#10 data_8b_in = 8'h81; ser_en = 1;
#10 ser_en = 0;
#10 $display("Input: 8'h%02h, Output: 10'h%03h", 8'h81, data_10b_out);
  #20 $display("=== Test completed ===");
#20 $finish;
end
// Monitor signals (optional - for console output)
initial begin
$monitor("Time=%0t rst=%b ser_en=%b data_in=%h data_out=%h",
$time, rst, ser_en, data_8b_in, data_10b_out);
end
endmodule
