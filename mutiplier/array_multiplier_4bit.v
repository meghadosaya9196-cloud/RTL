`timescale 1ns/1ps
module array_multiplier_4bit (
    input  [3:0] A, // Multiplicand
    input  [3:0] B, // Multiplier
    output [7:0] P  // Product
);

    wire [3:0] pp0, pp1, pp2, pp3; // Partial products
    wire [7:0] sum1, sum2, sum3;

    // Generate partial products
    assign pp0 = A & {4{B[0]}};
    assign pp1 = A & {4{B[1]}};
    assign pp2 = A & {4{B[2]}};
    assign pp3 = A & {4{B[3]}};

    // Shift and add partial products
    assign sum1 = {4'b0000, pp0};
    assign sum2 = {3'b000, pp1, 1'b0};
    assign sum3 = {2'b00, pp2, 2'b00};
    wire [7:0] sum4 = {1'b0, pp3, 3'b000};

    // Final addition
    assign P = sum1 + sum2 + sum3 + sum4;

endmodule

