module Adder_4(
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);

    // Brent-Kung Adder Implementation (4-bit)

    // 1. Generate and Propagate signals
    wire [3:0] p; // propagate: A_i ^ B_i
    wire [3:0] g; // generate: A_i & B_i

    assign p = A ^ B;
    assign g = A & B;

    // 2. Parallel Prefix Carry Tree (Brent-Kung structure)
    // This section computes the prefix generate terms G_i
    // G_i = g_i | (p_i & G_{i-1}), with G_{-1} = c_in
    // We need G_0, G_1, G_2, G_3 for carries c1, c2, c3, c4 (c_i = G_{i-1})

    // Level 1 (distance 1)
    wire G1_0, P1_0; // Combine bits 1 and 0
    wire G3_2, P3_2; // Combine bits 3 and 2

    // Black nodes (combine adjacent pairs)
    assign G1_0 = g[1] | (p[1] & g[0]);
    assign P1_0 = p[1] & p[0];

    assign G3_2 = g[3] | (p[3] & g[2]);
    assign P3_2 = p[3] & p[2];

    // Level 2 (distance 2)
    wire G3_0; // Combine result from G3_2/P3_2 and G1_0/P1_0

    // Black node
    assign G3_0 = G3_2 | (P3_2 & G1_0); // This computes G_3 (carry out)

    // White nodes / Intermediate carries needed for other sum bits
    wire G2_intermediate; // Needed for c3 (G_2)

    // G_2 = g_2 | (p_2 & G_1)
    // G_1 is G1_0 from Level 1
    assign G2_intermediate = g[2] | (p[2] & G1_0);


    // 3. Calculate carries into each bit position (c_i is carry into bit i)
    wire [4:0] c; // c[0] is input carry, c[1]..c[4] are internal carries

    // Assume input carry c0 is 0 for a simple adder
    assign c[0] = 1'b0;

    // c_{i+1} = G_i
    assign c[1] = g[0];           // Carry into bit 1 is G_0
    assign c[2] = G1_0;           // Carry into bit 2 is G_1
    assign c[3] = G2_intermediate; // Carry into bit 3 is G_2
    assign c[4] = G3_0;           // Carry into bit 4 (carry out) is G_3


    // 4. Calculate sum bits
    // sum_i = p_i ^ c_i
    wire [3:0] sum_bits;

    assign sum_bits[0] = p[0] ^ c[0]; // p0 ^ 0 = p0
    assign sum_bits[1] = p[1] ^ c[1];
    assign sum_bits[2] = p[2] ^ c[2];
    assign sum_bits[3] = p[3] ^ c[3];

    // 5. Final output
    // sum[4:0] = {carry_out, sum_bits[3:0]}
    assign sum = {c[4], sum_bits[3:0]};

endmodule