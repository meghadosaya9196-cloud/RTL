
module up_counter #(
    parameter int N = 4
) (
    input  wire         clk,
    input  wire         rst_n,   // active-low async reset
    input  wire         en,      // count enable
    output reg  [N-1:0] q
);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        q <= '0;
    else if (en)
        q <= q + 1'b1;   // wraps automatically modulo 2^N
end
endmodule
