`timescale 1ns/1ps

module tb_rca;

    // Parameters
    parameter N = 4;

    // Testbench signals (reg for inputs, wire for outputs)
    reg  [N-1:0] a;
    reg  [N-1:0] b;
    reg          cin;
    wire [N-1:0] sum;
    wire         cout;

    // Instantiate DUT
    rca #(.N(N)) dut (
        .a   (a),
        .b   (b),
        .cin (cin),
        .sum (sum),
        .cout(cout)
    );

    // Stimulus
    initial begin
        // Monitor values
        $monitor("time=%0t a=%b b=%b cin=%b -> sum=%b cout=%b",
                  $time, a, b, cin, sum, cout);

        // Test cases
        a = 4'b0000; b = 4'b0000; cin = 0; #10;
        a = 4'b0011; b = 4'b0101; cin = 0; #10;
        a = 4'b1111; b = 4'b0001; cin = 0; #10;
        a = 4'b1010; b = 4'b0101; cin = 1; #10;
        a = 4'b1111; b = 4'b1111; cin = 1; #10;

        $finish;
    end

endmodule
