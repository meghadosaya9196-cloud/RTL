
`timescale 1ns / 1ps

module tb_array_multiplier_4bit;

    // Inputs
    reg [3:0] A;
    reg [3:0] B;

    // Output
    wire [7:0] P;

    // Instantiate the Unit Under Test (UUT)
    array_multiplier_4bit uut (
        .A(A),
        .B(B),
        .P(P)
    );

    initial begin
        // Display header
        $display("Time\tA\tB\tProduct");
        $monitor("%g\t%b\t%b\t%b", $time, A, B, P);

        // Test cases
        A = 4'b0000; B = 4'b0000; #10;
        A = 4'b0001; B = 4'b0001; #10;
        A = 4'b0010; B = 4'b0011; #10;
        A = 4'b0101; B = 4'b0011; #10;
        A = 4'b1111; B = 4'b1111; #10;
        A = 4'b1001; B = 4'b0110; #10;

        // Finish simulation
        $finish;
    end

endmodule

