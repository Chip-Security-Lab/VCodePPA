//SystemVerilog
module Adder_10(
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);

    // Brent-Kung Adder Implementation (4-bit + 4-bit -> 5-bit)

    // Step 1: Generate and Propagate signals
    wire [3:0] p; // Propagate: pi = Ai ^ Bi
    wire [3:0] g; // Generate: gi = Ai & Bi

    assign p = A ^ B;
    assign g = A & B;

    // Step 2: Prefix tree computation (Brent-Kung structure)
    // (G, P) . (g', p') = (G | (P & g'), P & p')

    // Level 1 (Distance 1) - Black nodes
    wire G1_1; // GG[1:0]
    wire P1_1; // PP[1:0]
    assign G1_1 = g[1] | (p[1] & g[0]);
    assign P1_1 = p[1] & p[0];

    wire G1_3; // GG[3:2]
    wire P1_3; // PP[3:2]
    assign G1_3 = g[3] | (p[3] & g[2]);
    assign P1_3 = p[3] & p[2];

    // Level 2 (Distance 2) - Black nodes
    wire G2_3; // GG[3:0]
    wire P2_3; // PP[3:0]
    assign G2_3 = G1_3 | (P1_3 & G1_1);
    assign P2_3 = P1_3 & P1_1;

    // Backward Pass - Grey nodes
    // Level 1 (Distance 1) - using Level 1 black results
    wire G_bk_2; // GG[2:0]
    wire P_bk_2; // PP[2:0]
    assign G_bk_2 = g[2] | (p[2] & G1_1); // (g_2, p_2) . (G1_1, P1_1)
    assign P_bk_2 = p[2] & P1_1;

    // Step 3: Compute carries
    // c_i is the carry INTO bit i. c[0] is the carry-in.
    // For A + B, carry-in is 0.
    wire [4:0] c;
    wire c_in = 1'b0;

    assign c[0] = c_in;
    // c[1] = GG[0:-1] | (PP[0:-1] & c_in) = g[0] | (p[0] & c_in)
    assign c[1] = g[0] | (p[0] & c[0]);
    // c[2] = GG[1:0] | (PP[1:0] & c_in)
    assign c[2] = G1_1 | (P1_1 & c[0]);
    // c[3] = GG[2:0] | (PP[2:0] & c_in)
    assign c[3] = G_bk_2 | (P_bk_2 & c[0]);
    // c[4] = GG[3:0] | (PP[3:0] & c_in) - This is the carry-out
    assign c[4] = G2_3 | (P2_3 & c[0]);


    // Step 4: Compute sum bits
    wire [4:0] sum_wire;
    assign sum_wire[0] = p[0] ^ c[0];
    assign sum_wire[1] = p[1] ^ c[1];
    assign sum_wire[2] = p[2] ^ c[2];
    assign sum_wire[3] = p[3] ^ c[3];
    assign sum_wire[4] = c[4]; // The carry-out is the sum's MSB

    assign sum = sum_wire;

endmodule