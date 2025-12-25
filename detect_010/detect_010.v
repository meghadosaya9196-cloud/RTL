`timescale 1ns/1ps

module detect_010 (
    input  wire clk,
    input  wire reset,
    input  wire S,
    output wire Y
);

    wire Q1, Q2;   // history storage
    wire nQ2, nS;

    // First flip-flop: stores S(n-1)
    dff ff1 (.clk(clk), .reset(reset), .D(S),  .Q(Q1));

    // Second flip-flop: stores S(n-2)
    dff ff2 (.clk(clk), .reset(reset), .D(Q1), .Q(Q2));

    // Inverters
    assign nQ2 = ~Q2;
    assign nS  = ~S;

    // Output: detect 0-1-0
    assign Y = nQ2 & Q1 & nS;

endmodule 
