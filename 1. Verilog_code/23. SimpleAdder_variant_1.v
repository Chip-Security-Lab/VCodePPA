// Top-level module: 4-bit Adder using Carry-Lookahead
// This module performs a 4-bit addition A + B
module Adder_1 (
    input wire [3:0] A,   // 4-bit first operand
    input wire [3:0] B,   // 4-bit second operand
    output wire [4:0] sum // 5-bit sum (includes carry-out)
);

    // Internal signals for Carry-Lookahead logic
    wire [3:0] P; // Propagate signals P[i] = A[i] ^ B[i]
    wire [3:0] G; // Generate signals G[i] = A[i] & B[i]
    wire [4:0] C; // Carries C[i] is carry-in to bit i, C[4] is carry-out

    // Calculate Propagate and Generate signals for each bit
    assign P = A ^ B;
    assign G = A & B;

    // Input carry (c0) is 0 for simple addition
    assign C[0] = 1'b0;

    // Calculate carries using Carry-Lookahead logic
    // C[i+1] calculated directly from G[0..i], P[0..i], and C[0]
    assign C[1] = G[0];
    assign C[2] = G[1] | (P[1] & G[0]);
    assign C[3] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]);
    assign C[4] = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]);

    // Calculate sum bits
    // sum[i] = P[i] ^ C[i]
    assign sum[0] = P[0];
    assign sum[1] = P[1] ^ C[1];
    assign sum[2] = P[2] ^ C[2];
    assign sum[3] = P[3] ^ C[3];

    // The carry-out is the MSB of the sum
    assign sum[4] = C[4];

endmodule