module csa_block_4bit(
	input [3:0]a,
	input [3:0]b,
	input cin,
	output [3:0]sum,
	output cout,
	output p_block);

wire c1,c2,c3,c4_ripple_carry;
wire p0,p1,p2,p3;

// Individual propagate signals

assign p0=a[0]^b[0];
assign p1=a[1]^b[1];
assign p2=a[2]^b[2];
assign p3=a[3]^b[3];

// block propagate when all bits propagate

assign p_block=p0&p1&p2&p3;

full_adder fa0(
	.a(a[0]),
	.b(b[0]),
	.cin(cin),
	.cout(c1),
	.sum(sum[0]));

full_adder fa1(
	.a(a[1]),
	.b(b[1]),
	.cin(c1),
	.cout(c2),
	.sum(sum[1]));

full_adder fa2(
	.a(a[2]),
	.b(b[2]),
	.cin(c2),
	.cout(c3),
	.sum(sum[2]));

full_adder fa3(
	.a(a[3]),
	.b(b[3]),
	.cin(c3),
	.cout(c4_ripple_carry),
	.sum(sum[3]));

//skip MUX:
//if all bits propagate carry skips the block else use ripple carry output
 
assign cout= p_block? cin : c4_ripple_carry;
endmodule
