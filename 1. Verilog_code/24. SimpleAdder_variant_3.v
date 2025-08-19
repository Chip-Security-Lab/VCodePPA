//-----------------------------------------------------------------------------
// Brent-Kung Adder (N=4)
// Replaces simple '+' operator with a parallel prefix adder structure.
// Computes A[3:0] + B[3:0] = sum[4:0]
//-----------------------------------------------------------------------------
module Adder_2(
    input wire [3:0] A,
    input wire [3:0] B,
    output wire [4:0] sum
);

    // Internal signals for Generate (g) and Propagate (p)
    wire [3:0] g; // gi = Ai & Bi
    wire [3:0] p; // pi = Ai ^ Bi

    // Internal signals for Carries (C)
    // C[i] is the carry-in to bit i. C[0] is the global carry-in (assumed 0).
    // C[4] is the carry-out of the 4-bit addition.
    wire [4:0] C;

    // 1. Generate and Propagate (Level 0)
    assign g = A & B;
    assign p = A ^ B;

    // 2. Prefix Carry Computation (Brent-Kung N=4 Structure)
    // Intermediate Group Generate (G) and Group Propagate (P) signals.
    // Naming convention: G/P_highest_bit_level

    // Level 1 nodes (distance 1, combine i with i-1)
    wire G_1_1, P_1_1; // Group [1:0]
    wire G_3_1, P_3_1; // Group [3:2]

    // combine( (gi, pi), (gj, pj) ) -> (gi | pi & gj, pi & pj) where i > j
    assign G_1_1 = g[1] | (p[1] & g[0]);
    assign P_1_1 = p[1] & p[0];

    assign G_3_1 = g[3] | (p[3] & g[2]);
    assign P_3_1 = p[3] & p[2];

    // Level 2 nodes (distance 2, combine i with i-2)
    // These nodes generate the required carries C[3] and C[4]
    wire G_2_2; // Group [2:0] effectively, for C[3]
    wire G_3_2; // Group [3:0], for C[4]

    // Carry C[3] comes from combining (g2,p2) and (g0,p0)
    assign G_2_2 = g[2] | (p[2] & g[0]);

    // Carry C[4] comes from combining group [3:2] (G_3_1, P_3_1) and group [1:0] (G_1_1, P_1_1)
    assign G_3_2 = G_3_1 | (P_3_1 & G_1_1);

    // 3. Determine Carries C[i]
    // C[0] is the input carry (0 for simple adder)
    // C[i] for i=1..4 derived from the prefix network
    assign C[0] = 1'b0;
    assign C[1] = g[0];      // Carry into bit 1 is generate from bit 0
    assign C[2] = G_1_1;     // Carry into bit 2 is G[1:0]
    assign C[3] = G_2_2;     // Carry into bit 3 (specific BK structure)
    assign C[4] = G_3_2;     // Carry into bit 4 (Carry Out) is G[3:0]

    // 4. Sum Computation
    // sum[i] = p[i] ^ C[i] for i = 0..3
    // sum[4] = C[4] (carry out)
    assign sum[0] = p[0] ^ C[0]; // = p[0]
    assign sum[1] = p[1] ^ C[1];
    assign sum[2] = p[2] ^ C[2];
    assign sum[3] = p[3] ^ C[3];
    assign sum[4] = C[4]; // The carry-out is the most significant bit of sum

endmodule