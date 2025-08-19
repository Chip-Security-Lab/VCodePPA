module Adder_8(
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);

    // Width of the adder (excluding carry-out)
    localparam N = 4;

    // Initial Propagate (P) and Generate (G) signals for each bit position
    wire [N-1:0] p_init; // p_init[i] = A[i] ^ B[i]
    wire [N-1:0] g_init; // g_init[i] = A[i] & B[i]

    assign p_init = A ^ B;
    assign g_init = A & B;

    // Kogge-Stone Prefix Tree Stages (Propagate and Generate for ranges)
    // p_Lx[i], g_Lx[i] represent the propagate/generate for the range ending at index i, covering 2^x bits.

    // Level 1 (distance 2^1 = 2)
    wire [N-1:0] p_L1;
    wire [N-1:0] g_L1;

    // Level 2 (distance 2^2 = 4)
    wire [N-1:0] p_L2;
    wire [N-1:0] g_L2;

    // Level 0 (Pass through to Level 1)
    assign p_L1[0] = p_init[0];
    assign g_L1[0] = g_init[0];

    // Level 1 computations (i = 1 to N-1)
    // Combine pairs (i, i-1)
    assign p_L1[1] = p_init[1] & p_init[0];
    assign g_L1[1] = g_init[1] | (p_init[1] & g_init[0]);

    assign p_L1[2] = p_init[2] & p_init[1];
    assign g_L1[2] = g_init[2] | (p_init[2] & g_init[1]);

    assign p_L1[3] = p_init[3] & p_init[2];
    assign g_L1[3] = g_init[3] | (p_init[3] & g_init[2]);

    // Level 1 (Pass through to Level 2)
    assign p_L2[0] = p_L1[0];
    assign g_L2[0] = g_L1[0];

    assign p_L2[1] = p_L1[1];
    assign g_L2[1] = g_L1[1];

    // Level 2 computations (i = 2 to N-1)
    // Combine results with distance 2 (i, i-2)
    assign p_L2[2] = p_L1[2] & p_L1[0];
    assign g_L2[2] = g_L1[2] | (p_L1[2] & g_L1[0]);

    assign p_L2[3] = p_L1[3] & p_L1[1];
    assign g_L2[3] = g_L1[3] | (p_L1[3] & g_L1[1]);

    // Calculate carries (carries[i] is carry INTO bit i)
    // carries[0] is the input carry (cin), which is 0 for A+B
    // carries[1] is carry into bit 1
    // carries[2] is carry into bit 2
    // carries[3] is carry into bit 3
    // carries[4] is carry out of bit 3 (sum[4])
    wire [N:0] carries;

    // Input carry is 0 for A+B
    assign carries[0] = 1'b0;

    // Carries are derived from the final level G signals and the input carry
    // c[i+1] = G_final[i] | (P_final[i] & c[0])
    // With carries[0] = 0, carries[i+1] = G_final[i]
    // For N=4, the final level is Level 2.
    // carries[1] = g_L2[0]
    // carries[2] = g_L2[1]
    // carries[3] = g_L2[2]
    // carries[4] = g_L2[3]

    assign carries[1] = g_L2[0];
    assign carries[2] = g_L2[1];
    assign carries[3] = g_L2[2];
    assign carries[4] = g_L2[3];

    // Calculate sum bits
    // sum[i] = p_init[i] ^ carries[i]
    assign sum[0] = p_init[0] ^ carries[0];
    assign sum[1] = p_init[1] ^ carries[1];
    assign sum[2] = p_init[2] ^ carries[2];
    assign sum[3] = p_init[3] ^ carries[3];

    // Assign carry-out to sum[4]
    assign sum[4] = carries[4];

endmodule