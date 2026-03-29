module csa_16bit(
	input [15:0]a,
	input [15:0]b,
	input cin,
	output [15:0]sum,
	output cout,
	output [3:0]p_block);

wire c_skip_0,c_skip_1,c_skip_2;

csa_block_4bit block0(
	.a(a[3:0]),
	.b(b[3:0]),
	.cin(cin),
	.sum(sum[3:0]),
	.cout(c_skip_0),
	.p_block(p_block[0]));

csa_block_4bit block1(
	.a(a[7:4]),
	.b(b[7:4]),
	.cin(c_skip_0),
	.sum(sum[7:4]),
	.cout(c_skip_1),
	.p_block(p_block[1]));

csa_block_4bit block2(
	.a(a[11:8]),
	.b(b[11:8]),
	.cin(c_skip_1),
	.sum(sum[11:8]),
	.cout(c_skip_2),
	.p_block(p_block[2]));

csa_block_4bit block3(
	.a(a[15:12]),
	.b(b[15:12]),
	.cin(c_skip_2),
	.sum(sum[15:12]),
	.cout(cout),
	.p_block(p_block[3]));

endmodule
