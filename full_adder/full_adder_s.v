`timescale 1ns/1ps
module full_adder(
	input a,
	input b,
	input cin,
	output sum,
	output cout);
wire axb,anb;

assign axb= a^b; // propagate
assign anb= a&b; // generate
assign sum = (axb)^cin;
assign cout= (anb)|(axb)&cin;
endmodule
