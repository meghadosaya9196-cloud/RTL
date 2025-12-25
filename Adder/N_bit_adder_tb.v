`timescale 1ns/1ns

module tb_full_adder;

	localparam N=8;
	reg [N-1:0]a;
	reg [N-1:0]b;
	reg cin;
	wire [N-1:0]sum;
	wire cout;
	
	full_adder #N dut(.a(a),.b(b),.cin(cin),.sum(sum),.cout(cout));

	initial begin 
		a=8'b0000_0001;b=8'b0001_1000;cin=0;#10;
		a=8'b0010_0100;b=8'b0011_1100;cin=1;#10;
		a=8'd10;b=8'd2;cin=0;#10;
		a=8'd128;b=8'd128;cin=0;#10;

	$finish;
	end
endmodule
