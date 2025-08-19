//==============================================================================
// Top Module: 8-bit Kogge-Stone Adder
// Instantiates submodules for different stages of the adder.
//==============================================================================
module recursive_adder (
    input [7:0] a, b,
    input cin,
    output [7:0] sum,
    output cout
);

    // Internal wires connecting submodules
    wire [7:0] p, g;             // Generate and Propagate signals
    wire [7:0] G_final, P_final; // Final prefix Generate/Propagate signals
    wire [7:0] c_in_bit;         // Carry-in to each bit (c_in_bit[i] is carry into bit i)

    // Step 1: Generate and Propagate
    gp_generator u_gp_generator (
        .a(a),
        .b(b),
        .p(p),
        .g(g)
    );

    // Step 2 & 3: Prefix Tree Calculation and Final GP selection
    prefix_tree_8bit u_prefix_tree (
        .p(p),
        .g(g),
        .G_final(G_final),
        .P_final(P_final)
    );

    // Step 4 & 6: Carry Calculation and Carry Out
    carry_calculator_8bit u_carry_calculator (
        .G_final(G_final),
        .P_final(P_final),
        .cin(cin),
        .c_in_bit(c_in_bit),
        .cout(cout)
    );

    // Step 5: Sum Calculation
    sum_calculator_8bit u_sum_calculator (
        .p(p),
        .c_in_bit(c_in_bit),
        .sum(sum)
    );

endmodule

//==============================================================================
// Submodule: gp_generator
// Calculates the initial generate (g) and propagate (p) signals for each bit.
// g[i] = a[i] & b[i]
// p[i] = a[i] ^ b[i]
//==============================================================================
module gp_generator (
    input [7:0] a, b,
    output [7:0] p, g
);

    assign p = a ^ b;
    assign g = a & b;

endmodule

//==============================================================================
// Submodule: prefix_tree_8bit
// Implements the Kogge-Stone prefix tree logic to compute the final prefix
// generate (G_final) and propagate (P_final) signals for each bit position.
// This module contains the logic for levels 1, 2, and 3 of an 8-bit tree.
//==============================================================================
module prefix_tree_8bit (
    input [7:0] p, g,
    output [7:0] G_final, P_final
);

    // Intermediate prefix signals at different levels
    // P[level][bit_idx], G[level][bit_idx]
    // Level 0: p, g (input)
    wire [7:1] P1, G1; // Level 1 (step = 1)
    wire [7:2] P2, G2; // Level 2 (step = 2)
    wire [7:4] P3, G3; // Level 3 (step = 4)

    // Level 1 (step=1):
    // G1[i] = g[i] | (p[i] & g[i-1])
    // P1[i] = p[i] & p[i-1]
    // Valid for i = 1 to 7
    assign G1[1] = g[1] | (p[1] & g[0]); assign P1[1] = p[1] & p[0];
    assign G1[2] = g[2] | (p[2] & g[1]); assign P1[2] = p[2] & p[1];
    assign G1[3] = g[3] | (p[3] & g[2]); assign P1[3] = p[3] & p[2];
    assign G1[4] = g[4] | (p[4] & g[3]); assign P1[4] = p[4] & p[3];
    assign G1[5] = g[5] | (p[5] & g[4]); assign P1[5] = p[5] & p[4];
    assign G1[6] = g[6] | (p[6] & g[5]); assign P1[6] = p[6] & p[5];
    assign G1[7] = g[7] | (p[7] & g[6]); assign P1[7] = p[7] & p[6];

    // Level 2 (step=2):
    // G2[i] = G1[i] | (P1[i] & G1[i-2])
    // P2[i] = P1[i] & P1[i-2]
    // Valid for i = 2 to 7. Uses G1/P1 from i-2. G1[0]=g[0], P1[0]=p[0]
    assign G2[2] = G1[2] | (P1[2] & g[0]); assign P2[2] = P1[2] & p[0];
    assign G2[3] = G1[3] | (P1[3] & G1[1]); assign P2[3] = P1[3] & P1[1];
    assign G2[4] = G1[4] | (P1[4] & G1[2]); assign P2[4] = P1[4] & P1[2];
    assign G2[5] = G1[5] | (P1[5] & G1[3]); assign P2[5] = P1[5] & P1[3];
    assign G2[6] = G1[6] | (P1[6] & G1[4]); assign P2[6] = P1[6] & P1[4];
    assign G2[7] = G1[7] | (P1[7] & G1[5]); assign P2[7] = P1[7] & P1[5];

    // Level 3 (step=4):
    // G3[i] = G2[i] | (P2[i] & G2[i-4])
    // P3[i] = P2[i] & P2[i-4]
    // Valid for i = 4 to 7. Uses G2/P2 from i-4. G2[0]=g[0], P2[0]=p[0], G2[1]=G1[1], P2[1]=P1[1]
    assign G3[4] = G2[4] | (P2[4] & g[0]); assign P3[4] = P2[4] & p[0];
    assign G3[5] = G2[5] | (P2[5] & G1[1]); assign P3[5] = P2[5] & P1[1];
    assign G3[6] = G2[6] | (P2[6] & G2[2]); assign P3[6] = P2[6] & P2[2];
    assign G3[7] = G2[7] | (P2[7] & G2[3]); assign P3[7] = P2[7] & P2[3];

    // Final Prefix Signals (G_final, P_final)
    // G_final[i] = G[i][log2(N)] for i=0..7, where G[i][0] = g[i]
    // P_final[i] = P[i][log2(N)] for i=0..7, where P[i][0] = p[i]
    // For N=8, log2(N)=3.
    // G_final[i] is the prefix generate for bit i, considering all bits 0 to i.
    // P_final[i] is the prefix propagate for bit i, considering all bits 0 to i.
    assign G_final[0] = g[0];   assign P_final[0] = p[0];   // Level 0
    assign G_final[1] = G1[1];  assign P_final[1] = P1[1];  // Level 1
    assign G_final[2] = G2[2];  assign P_final[2] = P2[2];  // Level 2
    assign G_final[3] = G2[3];  assign P_final[3] = P2[3];  // Level 2
    assign G_final[4] = G3[4];  assign P_final[4] = P3[4];  // Level 3
    assign G_final[5] = G3[5];  assign P_final[5] = P3[5];  // Level 3
    assign G_final[6] = G3[6];  assign P_final[6] = P3[6];  // Level 3
    assign G_final[7] = G3[7];  assign P_final[7] = P3[7];  // Level 3

endmodule

//==============================================================================
// Submodule: carry_calculator_8bit
// Calculates the carry-in for each bit position and the final carry-out.
// c_in_bit[i] = G_final[i-1] | (P_final[i-1] & cin) for i = 1 to 7
// c_in_bit[0] = cin
// cout = G_final[7] | (P_final[7] & cin)
//==============================================================================
module carry_calculator_8bit (
    input [7:0] G_final, P_final,
    input cin,
    output [7:0] c_in_bit, // c_in_bit[i] is carry into bit i
    output cout
);

    // Carry into bit 0 is the external carry-in
    assign c_in_bit[0] = cin;

    // Carry into bit i (i=1 to 7)
    // This is the carry generated or propagated from bits 0 to i-1, combined with cin.
    // The prefix signals G_final[i-1] and P_final[i-1] represent the generate and
    // propagate conditions for the block of bits 0 to i-1.
    assign c_in_bit[1] = G_final[0] | (P_final[0] & cin);
    assign c_in_bit[2] = G_final[1] | (P_final[1] & cin);
    assign c_in_bit[3] = G_final[2] | (P_final[2] & cin);
    assign c_in_bit[4] = G_final[3] | (P_final[3] & cin);
    assign c_in_bit[5] = G_final[4] | (P_final[4] & cin);
    assign c_in_bit[6] = G_final[5] | (P_final[5] & cin);
    assign c_in_bit[7] = G_final[6] | (P_final[6] & cin);

    // Carry out is the carry into bit 8
    assign cout = G_final[7] | (P_final[7] & cin);

endmodule

//==============================================================================
// Submodule: sum_calculator_8bit
// Calculates the final sum bits.
// sum[i] = p[i] ^ c_in_bit[i] for i = 0 to 7
//==============================================================================
module sum_calculator_8bit (
    input [7:0] p,          // Propagate signal for each bit
    input [7:0] c_in_bit,   // Carry-in to each bit
    output [7:0] sum        // Final sum
);

    assign sum = p ^ c_in_bit;

endmodule