module Adder_5(
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);

    // Internal signals for Propagate (p) and Generate (g) for each bit
    wire [3:0] p;
    wire [3:0] g;

    // Internal signals for group Propagate (P) and Generate (G) from the Han-Carlson tree
    // N=4 adder, indices 0 to 3
    // Level 1 (span 2)
    wire P1_0; // P[1:0]
    wire G1_0; // G[1:0]
    wire P3_2; // P[3:2]
    wire G3_2; // G[3:2]

    // Internal signals for carries (C[i] is the carry-in to bit i+1)
    // C[1] is carry-in to bit 1 (from bit 0)
    // C[2] is carry-in to bit 2 (from bit 1)
    // C[3] is carry-in to bit 3 (from bit 2)
    // C[4] is carry-out from bit 3 (MSB carry)
    // Assuming carry-in to bit 0 (C0) is 0.
    wire [4:1] C;

    // Calculate bitwise p and g
    assign p = A ^ B;
    assign g = A & B;

    // Han-Carlson Prefix Tree for Carry Calculation (N=4, C0=0)
    // Level 1: Calculate P and G for pairs (span 2)
    assign P1_0 = p[1] & p[0];
    assign G1_0 = g[1] | (p[1] & g[0]);

    assign P3_2 = p[3] & p[2];
    assign G3_2 = g[3] | (p[3] & g[2]);

    // Level 2: Calculate required carries using intermediate P/G and bitwise p/g
    // C[i] = G[i-1:0] | (P[i-1:0] & C0). Since C0=0, C[i] = G[i-1:0]
    assign C[1] = g[0];         // C1 = G[0:0]
    assign C[2] = G1_0;         // C2 = G[1:0]
    assign C[3] = g[2] | (p[2] & G1_0); // C3 = G[2:0] = g[2] | (p[2] & G[1:0])
    assign C[4] = G3_2 | (P3_2 & G1_0); // C4 = G[3:0] = G[3:2] | (P[3:2] & G[1:0])

    // Calculate sum bits
    // sum[i] = p[i] ^ C[i] (where C[0] is the input carry, which is 0)
    assign sum[0] = p[0];       // S0 = p0 ^ C0 = p0 ^ 0
    assign sum[1] = p[1] ^ C[1];
    assign sum[2] = p[2] ^ C[2];
    assign sum[3] = p[3] ^ C[3];

    // The MSB of the sum is the final carry-out
    assign sum[4] = C[4];

endmodule