`timescale 1ns/1ps
module blocking(
	input clk,
	input a,
	output reg b,
	output reg c);

always @(posedge clk) begin
	b=a;
	c=b;
end
endmodule 
