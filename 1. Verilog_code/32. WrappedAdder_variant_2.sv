//SystemVerilog
module Adder_10(
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);

    // Parallel Prefix Adder (PPA) for 4-bit addition

    wire [3:0] p_sig; // Propagate signals p_i = A_i ^ B_i
    wire [3:0] g_sig; // Generate signals g_i = A_i & B_i

    // Layer 0: Generate and Propagate for each bit
    assign p_sig = A ^ B;
    assign g_sig = A & B;

    // Layer 1: Combine adjacent bits (groups of 2)
    // Gp_L<layer>_<end_bit>_<start_bit>[1] = G, [0] = P
    // (G_out, P_out) = (G_left, P_left) op (G_right, P_right)
    // (G_out, P_out) = (G_left | (P_left & G_right), P_left & P_right)

    // Node for [1:0]: (g[1], p[1]) op (g[0], p[0])
    wire [1:0] Gp_L1_1_0;
    assign Gp_L1_1_0[1] = g_sig[1] | (p_sig[1] & g_sig[0]); // G[1:0]
    assign Gp_L1_1_0[0] = p_sig[1] & p_sig[0];             // P[1:0]

    // Node for [3:2]: (g[3], p[3]) op (g[2], p[2])
    wire [1:0] Gp_L1_3_2;
    assign Gp_L1_3_2[1] = g_sig[3] | (p_sig[3] & g_sig[2]); // G[3:2]
    assign Gp_L1_3_2[0] = p_sig[3] & p_sig[2];             // P[3:2]

    // Layer 2: Combine size 2 groups (size 4 group)
    // Node for [3:0]: (G[3:2], P[3:2]) op (G[1:0], P[1:0])
    wire [1:0] Gp_L2_3_0;
    assign Gp_L2_3_0[1] = Gp_L1_3_2[1] | (Gp_L1_3_2[0] & Gp_L1_1_0[1]); // G[3:0]
    // Gp_L2_3_0[0] = Gp_L1_3_2[0] & Gp_L1_1_0[0]; // P[3:0] - Not strictly needed for carries

    // Carry Calculation (c[i] is carry into bit i)
    // c[i] = G[i-1:0]
    wire [4:0] carry_in;

    assign carry_in[0] = 1'b0; // Initial carry-in (assuming A+B, not A+B+Cin)
    assign carry_in[1] = g_sig[0]; // c[1] = G[0:0]
    assign carry_in[2] = Gp_L1_1_0[1]; // c[2] = G[1:0]
    // c[3] = G[2:0] = (g[2], p[2]) op (G[1:0], P[1:0])
    assign carry_in[3] = g_sig[2] | (p_sig[2] & Gp_L1_1_0[1]);
    assign carry_in[4] = Gp_L2_3_0[1]; // c[4] = G[3:0] (Carry-out)

    // Sum Calculation
    assign sum[0] = p_sig[0] ^ carry_in[0];
    assign sum[1] = p_sig[1] ^ carry_in[1];
    assign sum[2] = p_sig[2] ^ carry_in[2];
    assign sum[3] = p_sig[3] ^ carry_in[3];
    assign sum[4] = carry_in[4]; // The carry-out is the MSB of the sum

endmodule