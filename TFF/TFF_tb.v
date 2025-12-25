`timescale 1ns/1ns
module tb_TFF;
reg T;
reg clk;
reg reset;
wire Q;

tff DUT(.T(T),.clk(clk),.reset(reset),.Q(Q));

initial clk=0;
always #5 clk=~clk;

initial begin
	T=0;
	reset=0;
	
	#7 reset=0;
	#5 T=1;
	#12 reset=1;
	#13 T=1;
	#17 T=0;
	$finish;
	end
endmodule


	

