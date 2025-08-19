// Top level module for a 4-bit adder using Han-Carlson parallel prefix algorithm
// This module replaces the ripple-carry structure with a faster carry computation.
module Adder_2(
    input wire [3:0] A, // First 4-bit input operand
    input wire [3:0] B, // Second 4-bit input operand
    output wire [4:0] sum // 5-bit output sum (including carry-out)
);

    // Internal signals for Generate and Propagate
    wire [3:0] p; // Propagate: A[i] ^ B[i]
    wire [3:0] g; // Generate: A[i] & B[i]

    // Calculate initial Generate and Propagate signals for each bit
    assign p = A ^ B;
    assign g = A & B;

    // Internal signals for Group Generate (G) and Group Propagate (P)
    // These represent the G and P signals at different levels of the prefix tree
    // gp_level[level][bit_index] stores {G, P} for a range ending at bit_index

    // Level 0: Initial G and P for each bit [i:i]
    wire [3:0] G_level0, P_level0;
    assign G_level0 = g;
    assign P_level0 = p;

    // Level 1: Combine adjacent bits (distance 2^0 = 1)
    // Node at index i combines range ending at i with range ending at i-1
    // Ranges: [1:0], [2:1], [3:2]
    // Han-Carlson passes through some signals
    wire [3:0] G_level1, P_level1;
    assign G_level1[0] = G_level0[0]; // Pass through G[0:0]
    assign P_level1[0] = P_level0[0]; // Pass through P[0:0]
    assign G_level1[1] = G_level0[1] | (P_level0[1] & G_level0[0]); // G[1:0] = G[1:1] | (P[1:1] & G[0:0])
    assign P_level1[1] = P_level0[1] & P_level0[0];                 // P[1:0] = P[1:1] & P[0:0]
    assign G_level1[2] = G_level0[2] | (P_level0[2] & G_level0[1]); // G[2:1]
    assign P_level1[2] = P_level0[2] & P_level0[1];                 // P[2:1]
    assign G_level1[3] = G_level0[3] | (P_level0[3] & G_level0[2]); // G[3:2]
    assign P_level1[3] = P_level0[3] & P_level0[2];                 // P[3:2]

    // Level 2: Combine results from Level 1 (distance 2^1 = 2)
    // Node at index i combines range ending at i with range ending at i-2
    // Ranges: [2:0], [3:0]
    // Han-Carlson passes through some signals
    wire [3:0] G_level2, P_level2;
    assign G_level2[0] = G_level1[0]; // Pass through G[0:0]
    assign P_level2[0] = P_level1[0]; // Pass through P[0:0]
    assign G_level2[1] = G_level1[1]; // Pass through G[1:0]
    assign P_level2[1] = P_level1[1]; // Pass through P[1:0]
    // G[2:0] = G[2:1] | (P[2:1] & G[0:0]) - uses G_level1[2], P_level1[2] and G_level0[0]
    assign G_level2[2] = G_level1[2] | (P_level1[2] & G_level0[0]);
    assign P_level2[2] = P_level1[2] & P_level0[0];
    // G[3:0] = G[3:2] | (P[3:2] & G[1:0]) - uses G_level1[3], P_level1[3] and G_level1[1]
    assign G_level2[3] = G_level1[3] | (P_level1[3] & G_level1[1]);
    assign P_level2[3] = P_level1[3] & P_level1[1];

    // Carries C_i (carry *into* bit i) are derived from G[i-1:0]
    // C_0 is the input carry (assumed 0 for this module based on original code)
    // C_1 = G[0:0]
    // C_2 = G[1:0]
    // C_3 = G[2:0]
    // C_4 = G[3:0] (final carry out)

    wire [4:0] carry_in_to_bit; // carry_in_to_bit[i] is the carry into bit i
    assign carry_in_to_bit[0] = 1'b0; // Input carry is 0
    assign carry_in_to_bit[1] = G_level0[0]; // G[0:0]
    assign carry_in_to_bit[2] = G_level1[1]; // G[1:0]
    assign carry_in_to_bit[3] = G_level2[2]; // G[2:0]
    assign carry_in_to_bit[4] = G_level2[3]; // G[3:0] (Final carry out)

    // Calculate sum bits: S_i = P_i ^ C_i
    wire [3:0] sum_bits;
    assign sum_bits[0] = p[0] ^ carry_in_to_bit[0];
    assign sum_bits[1] = p[1] ^ carry_in_to_bit[1];
    assign sum_bits[2] = p[2] ^ carry_in_to_bit[2];
    assign sum_bits[3] = p[3] ^ carry_in_to_bit[3];

    // Assign outputs
    assign sum[3:0] = sum_bits;
    assign sum[4]   = carry_in_to_bit[4];

endmodule