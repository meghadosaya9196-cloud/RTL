`timescale 1ns/1ps
module tb_decoder;
logic clk;
logic rst;
logic [9:0] data_10b_in;
logic par_en;
logic [7:0] data_8b_out;
// Instantiate the DUT (Device Under Test)
decoder dut (
.clk(clk),
.rst(rst),
.data_10b_in(data_10b_in),
.par_en(par_en),
.data_8b_out(data_8b_out)
);
// Clock generation (10ns period = 100MHz)
always #5 clk = ~clk;
// VCD dump - generates dump.vcd file for waveform viewing
initial begin
$dumpfile("decoder_dump.vcd");
$dumpvars(0, tb_decoder);
end
  initial begin
// Initialize signals
clk = 0;
rst = 1;
par_en = 0;
data_10b_in = 10'h000;
// Reset sequence
#20 rst = 0;
// Test case 1: 10'h240 (encodes 8'h00)
#10 data_10b_in = 10'h240; par_en = 1; // 0100_011000
#10 par_en = 0;
#10 $display("Input: 10'h%03h, Output: 8'h%02h (expected 00)", 10'h240, data_8b_out);
// Test case 2: 10'h47C (encodes 8'hFF)
#10 data_10b_in = 10'h47C; par_en = 1; // 0100_111100
#10 par_en = 0;
#10 $display("Input: 10'h%03h, Output: 8'h%02h (expected FF)", 10'h47C, data_8b_out);
// Test case 3: 10'h2AA (encodes 8'h55)
#10 data_10b_in = 10'h2AA; par_en = 1; // 0101_010101
#10 par_en = 0;
#10 $display("Input: 10'h%03h, Output: 8'h%02h (expected 55)", 10'h2AA, data_8b_out);
    // Test case 4: 10'h32A (encodes 8'hA5)
#10 data_10b_in = 10'h32A; par_en = 1; // 0011_010101
#10 par_en = 0;
#10 $display("Input: 10'h%03h, Output: 8'h%02h (expected A5)", 10'h32A, data_8b_out);
// Test case 5: 10'h27C (encodes 8'h0F)
#10 data_10b_in = 10'h27C; par_en = 1; // 0101_111100
#10 par_en = 0;
#10 $display("Input: 10'h%03h, Output: 8'h%02h (expected 0F)", 10'h27C, data_8b_out);
// Test case 6: 10'h090 (encodes 8'hF0)
#10 data_10b_in = 10'h090; par_en = 1; // 0001_001000
#10 par_en = 0;
#10 $display("Input: 10'h%03h, Output: 8'h%02h (expected F0)", 10'h090, data_8b_out);
// Test case 7: 10'h35A (encodes 8'hAA)
#10 data_10b_in = 10'h35A; par_en = 1; // 0011_010110
#10 par_en = 0;
#10 $display("Input: 10'h%03h, Output: 8'h%02h (expected AA)", 10'h35A, data_8b_out);
    // Test case 8: 10'h1CC (encodes 8'h33)
#10 data_10b_in = 10'h1CC; par_en = 1; // 0001_110100
#10 par_en = 0;
#10 $display("Input: 10'h%03h, Output: 8'h%02h (expected 33)", 10'h1CC, data_8b_out);
// Test case 9: 10'h374 (encodes 8'h7E)
#10 data_10b_in = 10'h374; par_en = 1; // 0011_111100
#10 par_en = 0;
#10 $display("Input: 10'h%03h, Output: 8'h%02h (expected 7E)", 10'h374, data_8b_out);
// Test case 10: 10'h486 (encodes 8'h81)
#10 data_10b_in = 10'h486; par_en = 1; // 0100_100110
#10 par_en = 0;
#10 $display("Input: 10'h%03h, Output: 8'h%02h (expected 81)", 10'h486, data_8b_out);
#20 $display("=== Decoder Test completed ===");
#20 $finish;
end
// Monitor signals (optional - for console output)
initial begin
$monitor("Time=%0t rst=%b par_en=%b data_in=%h data_out=%h",
$time, rst, par_en, data_10b_in, data_8b_out);
end
endmodule
