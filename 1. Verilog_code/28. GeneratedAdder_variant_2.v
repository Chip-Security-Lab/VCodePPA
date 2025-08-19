module Adder_6(
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);

    // Kogge-Stone Adder implementation for 4-bit inputs + 1-bit carry-out

    // Initial Generate (g) and Propagate (p) signals
    // g_init[i] = A[i] & B[i]
    // p_init[i] = A[i] | B[i] (using OR for propagate)
    wire [3:0] g_init;
    wire [3:0] p_init;

    assign g_init = A & B;
    assign p_init = A | B;

    // Stage 1 (distance 1) Generate/Propagate pairs (G[i:i-1], P[i:i-1])
    // gp_s1[i] = {G[i:i-1], P[i:i-1]}
    // G[i:j] = G[i:k] | (P[i:k] & G[k-1:j])
    // P[i:j] = P[i:k] & P[k-1:j]
    // For stage 1, k = i
    wire [1:0] gp_s1 [3:1]; // Indices 1, 2, 3

    assign gp_s1[1] = {g_init[1] | (p_init[1] & g_init[0]), p_init[1] & p_init[0]}; // G[1:0], P[1:0]
    assign gp_s1[2] = {g_init[2] | (p_init[2] & g_init[1]), p_init[2] & p_init[1]}; // G[2:1], P[2:1]
    assign gp_s1[3] = {g_init[3] | (p_init[3] & g_init[2]), p_init[3] & p_init[2]}; // G[3:2], P[3:2]

    // Stage 2 (distance 2) Generate/Propagate pairs (G[i:i-3], P[i:i-3])
    // gp_s2[i] = {G[i:i-3], P[i:i-3]}
    // For stage 2, k = i-2
    wire [1:0] gp_s2 [3:2]; // Indices 2, 3

    assign gp_s2[2] = {gp_s1[2][0] | (gp_s1[2][1] & g_init[0]), gp_s1[2][1] & p_init[0]}; // G[2:0], P[2:0] = G[2:1]|(P[2:1]&G[0:0]), P[2:1]&P[0:0]
    assign gp_s2[3] = {gp_s1[3][0] | (gp_s1[3][1] & gp_s1[1][0]), gp_s1[3][1] & gp_s1[1][1]}; // G[3:0], P[3:0] = G[3:2]|(P[3:2]&G[1:0]), P[3:2]&P[1:0]

    // Calculate carries (C[i] is the carry into bit i)
    // C[i+1] = G[i:0] | (P[i:0] & C[0])
    // Assuming C[0] (cin) = 0
    wire [4:0] carries; // carries[i] is carry into bit i

    assign carries[0] = 1'b0; // Carry-in to bit 0 is 0

    // C[1] = G[0:0] | (P[0:0] & C[0]) = g_init[0] | (p_init[0] & carries[0])
    assign carries[1] = g_init[0] | (p_init[0] & carries[0]);

    // C[2] = G[1:0] | (P[1:0] & C[0]) = gp_s1[1][0] | (gp_s1[1][1] & carries[0])
    assign carries[2] = gp_s1[1][0] | (gp_s1[1][1] & carries[0]);

    // C[3] = G[2:0] | (P[2:0] & C[0]) = gp_s2[2][0] | (gp_s2[2][1] & carries[0])
    assign carries[3] = gp_s2[2][0] | (gp_s2[2][1] & carries[0]);

    // C[4] = G[3:0] | (P[3:0] & C[0]) = gp_s2[3][0] | (gp_s2[3][1] & carries[0])
    assign carries[4] = gp_s2[3][0] | (gp_s2[3][1] & carries[0]);

    // Calculate sum bits
    // sum[i] = A[i] ^ B[i] ^ C[i]
    assign sum[0] = A[0] ^ B[0] ^ carries[0];
    assign sum[1] = A[1] ^ B[1] ^ carries[1];
    assign sum[2] = A[2] ^ B[2] ^ carries[2];
    assign sum[3] = A[3] ^ B[3] ^ carries[3];

    // The most significant bit of the sum is the final carry-out
    assign sum[4] = carries[4];

endmodule