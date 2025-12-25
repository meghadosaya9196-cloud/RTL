`timescale 1ns/1ns

module tff(
	input clk,
	input T,
	input reset,
	output reg Q
	);
	
	always @(negedge clk or negedge reset) begin
		if (!reset)
			Q<=1'b0;
		else if(T)
			Q<=~Q;
		else
			Q<=Q;
	end
endmodule
	
		
