module ALU #(parameter N=32)(

	input wire [N-1:0]a,
	input wire [N-1:0]b,
	input wire [2:0]sel,
	output reg [N:0]out,
	output reg carryout,
	output reg borrow,
	output reg overflow_sum,
	output reg overflow_sub );
	
	reg [N:0] sum;
	reg [N:0] sub;
	reg [N-1:0]shift_left;
	reg [N-1:0]shift_right;
	reg [N-1:0]AND;
	reg [N-1:0]OR;
	reg [N-1:0]XOR;
	reg [N-1:0]NAND;

	always @(*) begin
		out= {N{1'b0}};
		carryout=1'b0;
		borrow=1'b0;
		overflow_sum=1'b0;
		overflow_sub=1'b0;


		sum={1'b0,a}+{1'b0,b};
		carryout=sum[N];
		overflow_sum = (~(a[N-1] ^ b[N-1])) & (sum[N-1] ^ a[N-1]);
		
		sub={1'b0,a}-{1'b0,b};
		borrow = ~sub[N];
		overflow_sub = (a[N-1] ^ b[N-1]) & (sub[N-1] ^ a[N-1]);

		shift_left= a<<b[$clog2(N)-1:0];
		shift_right=a>>b[$clog2(N)-1:0];
		
		AND= a&b;
		OR=a|b;
		XOR=a^b;
		NAND=~(a&b);
		
		case(sel)
		
		3'b000:out=sum;
		3'b001:out=sub;
		3'b010:out=shift_left;
		3'b011:out=shift_right;
		3'b100:out=AND;
		3'b101:out=OR;
		3'b110:out=XOR;
		3'b111:out=NAND;

		endcase

	end
endmodule

