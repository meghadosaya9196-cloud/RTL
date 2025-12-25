module tb_subtractor;
	reg a;
	reg b;
	reg borrowin;
	wire subtraction;
	wire borrowout;

	subtractor dut(.a(a),.b(b),.borrowin(borrowin),.subtraction(subtraction),.borrowout(borrowout));
	
	initial begin
		a=0;b=1;borrowin=1;#10;
        	a=1;b=1;borrowin=1;#10;
		$finish;
	end
endmodule
