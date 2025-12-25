module tb_multiplier;
	reg a;
	reg b;
	wire p;

	multiplier dut(.a(a),.b(b),.p(p));
	initial begin
		a=0;b=1;#10;
		a=1;b=0;#10;
		a=1;b=0;#10;
		a=1;b=1;#10;
		$finish;
	end
endmodule
