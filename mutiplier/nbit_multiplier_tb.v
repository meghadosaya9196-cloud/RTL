module tb_n_bit_multiplier;
	localparam N=4;
	reg [N-1:0]a;
	reg [N-1:0]b;
	wire [2*N-1:0]p;

	n_bit_multiplier #(4) dut(.a(a),.b(b),.p(p));

	initial begin
		a=4'b0011;b=4'b1100;#10;
		a=4'b0101;b=4'b1010;#10;
		$finish;
	end
endmodule
