module subtractor(input a,
	input b,
	input borrowin,
	
	output subtraction,
	output borrowout);

	assign subtraction= a^b^borrowin;
	assign borrowout=  (~a&b)|(~a&borrowin)|(b&borrowin);

	endmodule

