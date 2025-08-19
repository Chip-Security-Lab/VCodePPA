module Adder_8(
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);

    // Signals for Generate (G) and Propagate (P)
    // G_i = A_i & B_i  (Carry Generate)
    // P_i = A_i ^ B_i  (Carry Propagate)
    wire [3:0] G;
    wire [3:0] P;

    // Signals for Carries (C)
    // C[0] is the input carry (fixed to 0)
    // C[1..3] are internal carries for bits 1, 2, 3
    // C[4] is the carry out
    wire [4:0] C;

    // Input carry is zero for simple addition
    assign C[0] = 1'b0;

    // Calculate Generate and Propagate signals for each bit position (parallel)
    assign G = A & B;
    assign P = A ^ B;

    // Calculate Carries in parallel using Carry-Lookahead expressions (assuming C[0]=0)
    // C[1] = G[0] | (P[0] & C[0]) --> G[0]
    // C[2] = G[1] | (P[1] & C[1]) --> G[1] | (P[1] & G[0])
    // C[3] = G[2] | (P[2] & C[2]) --> G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0])
    // C[4] = G[3] | (P[3] & C[3]) --> G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0])

    assign C[1] = G[0];
    assign C[2] = G[1] | (P[1] & G[0]);
    assign C[3] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]);
    assign C[4] = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]);

    // Calculate Sum bits (parallel)
    // sum[i] = P[i] ^ C[i]
    // sum[0] = P[0] ^ C[0] --> P[0]
    // sum[1] = P[1] ^ C[1]
    // sum[2] = P[2] ^ C[2]
    // sum[3] = P[3] ^ C[3]

    assign sum[0] = P[0];
    assign sum[1] = P[1] ^ C[1];
    assign sum[2] = P[2] ^ C[2];
    assign sum[3] = P[3] ^ C[3];

    // The carry out is the final calculated carry
    assign sum[4] = C[4];

endmodule