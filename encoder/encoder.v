module encoder(
	input [7:0]i,
	output reg [2:0]o);

	always @(*) begin
		case (i)
		8'b0000_0001: o=3'b000;
		8'b0000_0010: o=3'b001;
		8'b0000_0100: o=3'b010;
	  8'b0000_1000: o=3'b011;
		8'b0001_0000: o=3'b100;
		8'b0010_0000: o=3'b101;
		8'b0100_0000: o=3'b110;
		8'b1000_0000: o=3'b111;

		default : o=3'bxxx;
		endcase
	end
endmodule
