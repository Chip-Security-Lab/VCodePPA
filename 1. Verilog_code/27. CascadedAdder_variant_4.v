// Top level module for a 4-bit adder using a Brent-Kung structure.
// It adds two 4-bit numbers A and B and produces a 5-bit sum.
// The 5th bit of the sum is the carry-out from the most significant bit addition.
module Adder_5(
    input [3:0] A, // First 4-bit input operand
    input [3:0] B, // Second 4-bit input operand
    output [4:0] sum // 5-bit sum result (includes carry-out)
);

    // Wires for generate (g) and propagate (p) signals for each bit
    wire [3:0] p; // p[i] = A[i] ^ B[i]
    wire [3:0] g; // g[i] = A[i] & B[i]

    // Wires for intermediate generate (G) and propagate (P) signals
    // from the Brent-Kung carry tree levels.
    // G_Lx[i], P_Lx[i] represent the combined generate/propagate for a block
    // ending at index i after processing at level x.
    wire [3:0] g_L1, p_L1; // Level 1 G/P signals (distance 1 combines)
    wire [3:0] g_L2, p_L2; // Level 2 G/P signals (distance 2 combines)

    // Wires for the carries into each bit position (c_in_i is carry into bit i)
    wire c_in_1, c_in_2, c_in_3, c_in_4;

    // Brent-Kung Black Cell operation:
    // (G_out, P_out) = (G_left | (P_left & G_right), P_left & P_right)
    // This represents the generate and propagate for the combined block.

    // 1. Pre-processing: Calculate initial generate and propagate signals
    assign p = A ^ B;
    assign g = A & B;

    // 2. Carry Tree (Upward Pass): Compute intermediate G/P signals
    // Level 1 (combining adjacent bits, distance 1)
    // Index 0: Buffer (g0, p0)
    assign g_L1[0] = g[0];
    assign p_L1[0] = p[0];
    // Index 1: Black cell (g1,p1) + (g0,p0)
    assign g_L1[1] = g[1] | (p[1] & g[0]);
    assign p_L1[1] = p[1] & p[0];
    // Index 2: Buffer (g2, p2)
    assign g_L1[2] = g[2];
    assign p_L1[2] = p[2];
    // Index 3: Black cell (g3,p3) + (g2,p2)
    assign g_L1[3] = g[3] | (p[3] & g[2]);
    assign p_L1[3] = p[3] & p[2];

    // Level 2 (combining blocks of size 2, distance 2)
    // Index 0: Buffer (g0_L1, p0_L1)
    assign g_L2[0] = g_L1[0];
    assign p_L2[0] = p_L1[0];
    // Index 1: Buffer (g1_L1, p1_L1)
    assign g_L2[1] = g_L1[1];
    assign p_L2[1] = p_L1[1];
    // Index 2: Buffer (g2_L1, p2_L1)
    assign g_L2[2] = g_L1[2];
    assign p_L2[2] = p_L1[2];
    // Index 3: Black cell (g3_L1, p3_L1) + (g1_L1, p1_L1)
    assign g_L2[3] = g_L1[3] | (p_L1[3] & g_L1[1]);
    assign p_L2[3] = p_L1[3] & p_L1[1];

    // 3. Carry Calculation: Derive carries into each bit position (C_i)
    // C_0 = cin (which is 0 for this adder)
    // C_i = G for block [i-1:0] | (P for block [i-1:0] & C_0)
    // With C_0 = 0, C_i simplifies to G for block [i-1:0]

    // Carry into bit 0 (C_0) is 0 (implicit)

    // Carry into bit 1 (C_1) = G for block [0:0] = g[0]
    assign c_in_1 = g[0];

    // Carry into bit 2 (C_2) = G for block [1:0] = g1 | (p1 & g0) = g_L1[1]
    assign c_in_2 = g_L1[1];

    // Carry into bit 3 (C_3) = G for block [2:0] = g2 | (p2 & G for block [1:0]) = g2 | (p2 & c_in_2)
    assign c_in_3 = g[2] | (p[2] & c_in_2);

    // Carry into bit 4 (C_4) = G for block [3:0] = g_L2[3] (This is the final carry-out)
    assign c_in_4 = g_L2[3];

    // 4. Sum Calculation: sum[i] = p[i] ^ C_i
    // sum[0] = p[0] ^ C_0 = p[0] ^ 0
    assign sum[0] = p[0];
    assign sum[1] = p[1] ^ c_in_1;
    assign sum[2] = p[2] ^ c_in_2;
    assign sum[3] = p[3] ^ c_in_3;
    // The 5th bit of the sum is the final carry-out
    assign sum[4] = c_in_4;

endmodule