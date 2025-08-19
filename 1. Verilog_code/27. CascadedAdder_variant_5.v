// Top module: Instantiates and connects the submodules
module Adder_5 (
    input wire [3:0] A,
    input wire [3:0] B,
    output wire [4:0] sum
);

    // Internal signals
    wire [3:0] p_lvl0; // initial propagates
    wire [3:0] g_lvl0; // initial generates

    // Prefix tree intermediate signals
    // G[1:0], P[1:0] from level 1, distance 1 combine (bits 0 and 1)
    wire G_lvl1_1_0, P_lvl1_1_0;
    // G[3:2], P[3:2] from level 1, distance 1 combine (bits 2 and 3)
    wire G_lvl1_3_2, P_lvl1_3_2;
    // G[3:0], P[3:0] from level 2, distance 2 combine (bits 0-1 and 2-3)
    wire G_lvl2_3_0, P_lvl2_3_0;

    wire [4:0] carries; // carries[i] is carry-in to bit i (carries[0] is cin, carries[4] is cout)
    wire [3:0] sum_bits; // sum bits 0-3

    // Instantiate PG Generator
    // Generates initial propagate (A^B) and generate (A&B) for each bit
    PG_Generator pg_gen_inst (
        .A(A),
        .B(B),
        .p(p_lvl0),
        .g(g_lvl0)
    );

    // Instantiate Brent-Kung Prefix Tree
    // Computes prefix G/P pairs based on initial p/g signals
    Brent_Kung_Prefix_Tree_4bit prefix_tree_inst (
        .p_in(p_lvl0),
        .g_in(g_lvl0),
        .G_1_0(G_lvl1_1_0),
        .P_1_0(P_lvl1_1_0),
        .G_3_2(G_lvl1_3_2),
        .P_3_2(P_lvl1_3_2),
        .G_3_0(G_lvl2_3_0),
        .P_3_0(P_lvl2_3_0)
    );

    // Instantiate Carry Logic
    // Derives carries from initial p/g and prefix G signals
    Carry_Logic_4bit carry_calc_inst (
        .p_in(p_lvl0),
        .g_in(g_lvl0),
        .G_1_0(G_lvl1_1_0),
        .G_3_0(G_lvl2_3_0),
        .carries(carries)
    );

    // Instantiate Sum Logic
    // Computes final sum bits based on initial p and carries
    Sum_Logic_4bit sum_calc_inst (
        .p_in(p_lvl0),
        .carries_in(carries[3:0]), // carries[0] to carries[3] are carry-ins for bits 0 to 3
        .sum_bits(sum_bits)
    );

    // Final output: {carry_out, sum_bits}
    assign sum = {carries[4], sum_bits};

endmodule


// Submodule: Generates initial propagate (p) and generate (g) signals
module PG_Generator (
    input wire [3:0] A,
    input wire [3:0] B,
    output wire [3:0] p, // propagate: A[i] ^ B[i]
    output wire [3:0] g  // generate: A[i] & B[i]
);
    assign p = A ^ B;
    assign g = A & B;
endmodule

// Submodule: Implements the 4-bit Brent-Kung prefix tree structure
// Computes intermediate G/P pairs needed for carry calculation
module Brent_Kung_Prefix_Tree_4bit (
    input wire [3:0] p_in, // initial propagates
    input wire [3:0] g_in, // initial generates

    // Level 1 outputs (distance 1 combines)
    output wire G_1_0, P_1_0, // G[1:0], P[1:0]
    output wire G_3_2, P_3_2, // G[3:2], P[3:2]

    // Level 2 outputs (distance 2 combines)
    output wire G_3_0, P_3_0  // G[3:0], P[3:0]
);

    // Level 1 combines (distance 1)
    // Combine (g1, p1) and (g0, p0) -> G[1:0], P[1:0]
    Prefix_Combine_Block combine_1_0 (
        .g0(g_in[0]), .p0(p_in[0]),
        .g1(g_in[1]), .p1(p_in[1]),
        .G_out(G_1_0), .P_out(P_1_0)
    );

    // Combine (g3, p3) and (g2, p2) -> G[3:2], P[3:2]
    Prefix_Combine_Block combine_3_2 (
        .g0(g_in[2]), .p0(p_in[2]),
        .g1(g_in[3]), .p1(p_in[3]),
        .G_out(G_3_2), .P_out(P_3_2)
    );

    // Level 2 combines (distance 2)
    // Combine (G[3:2], P[3:2]) and (G[1:0], P[1:0]) -> G[3:0], P[3:0]
    Prefix_Combine_Block combine_3_0 (
        .g0(G_1_0), .p0(P_1_0),
        .g1(G_3_2), .p1(P_3_2),
        .G_out(G_3_0), .P_out(P_3_0)
    );

endmodule

// Submodule: Calculates carries based on initial p/g and prefix tree outputs
module Carry_Logic_4bit (
    input wire [3:0] p_in, // initial propagates
    input wire [3:0] g_in, // initial generates

    // Prefix tree outputs (specific Gs needed for carries)
    input wire G_1_0, // G[1:0]
    input wire G_3_0, // G[3:0]

    output wire [4:0] carries // carries[i] is carry-in to bit i (carries[0] is cin)
);
    // carries[0] is external carry-in (assumed 0 for this adder)
    // carries[1] = G[0:0] = g[0]
    // carries[2] = G[1:0]
    // carries[3] = G[2:0] = g[2] | (p[2] & G[1:0])
    // carries[4] = G[3:0] (carry-out from bit 3)

    assign carries[0] = 1'b0;
    assign carries[1] = g_in[0];
    assign carries[2] = G_1_0;
    assign carries[3] = g_in[2] | (p_in[2] & G_1_0);
    assign carries[4] = G_3_0;

endmodule

// Submodule: Calculates final sum bits
module Sum_Logic_4bit (
    input wire [3:0] p_in, // initial propagates
    input wire [3:0] carries_in, // carries[0] to carries[3] (carry-in to each bit)
    output wire [3:0] sum_bits
);
    // sum_bits[i] = p[i] ^ carry_in_to_bit_i
    assign sum_bits = p_in ^ carries_in;
endmodule

// Submodule: Performs the basic (g, p) combine operation
// G_out = g1 | (p1 & g0)
// P_out = p1 & p0
module Prefix_Combine_Block (
    input wire g0, p0, // right (less significant) group
    input wire g1, p1, // left (more significant) group
    output wire G_out, P_out
);
    assign G_out = g1 | (p1 & g0);
    assign P_out = p1 & p0;
endmodule