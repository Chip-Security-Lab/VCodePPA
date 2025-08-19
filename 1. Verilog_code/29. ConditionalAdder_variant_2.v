module Adder_7(
    input [3:0] A,
    input [3:0] B,
    output wire [4:0] sum
);

    // Extend inputs to 5 bits for 5-bit addition
    wire [4:0] A_ext = {1'b0, A};
    wire [4:0] B_ext = {1'b0, B};

    // Generate and Propagate signals for each bit position i = 0 to 4
    // G[i] = A_ext[i] & B_ext[i] (generate a carry at position i)
    // P[i] = A_ext[i] | B_ext[i] (propagate a carry through position i)
    wire [4:0] G;
    wire [4:0] P;

    assign G = A_ext & B_ext;
    assign P = A_ext | B_ext;

    // Carries (c_i is the carry-in to bit position i)
    // c0 is the initial carry-in, which is 0 for simple addition
    wire c0 = 1'b0;
    wire c1, c2, c3, c4; // c1 is carry-in to bit 1, c2 to bit 2, etc.

    // Carry Lookahead Logic: Compute carries c1 through c4 in parallel
    // The carry-out of stage i (carry-in to stage i+1) is c_{i+1}
    // c_{i+1} = G_i | (P_i & c_i)
    // Expanding carries in terms of G, P, and c0 (c0=0):
    // c1 = G0 | (P0 & c0) = G0
    // c2 = G1 | (P1 & c1) = G1 | P1(G0 | P0 c0) = G1 | P1 G0 | P1 P0 c0 = G1 | P1 G0
    // c3 = G2 | (P2 & c2) = G2 | P2(G1 | P1 G0 | P1 P0 c0) = G2 | P2 G1 | P2 P1 G0 | P2 P1 P0 c0 = G2 | P2 G1 | P2 P1 G0
    // c4 = G3 | (P3 & c3) = G3 | P3(G2 | P2 G1 | P2 P1 G0 | P3 P2 P1 P0 c0) = G3 | P3 G2 | P3 P2 G1 | P3 P2 P1 G0 | P3 P2 P1 P0 G0 = G3 | P3 G2 | P3 P2 G1 | P3 P2 P1 G0

    assign c1 = G[0];
    assign c2 = G[1] | (P[1] & G[0]);
    assign c3 = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]);
    assign c4 = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]);

    // Sum bits: S_i = (A_ext[i] ^ B_ext[i]) ^ c_i
    // Note: sum[i] corresponds to S_i
    assign sum[0] = (A_ext[0] ^ B_ext[0]) ^ c0;
    assign sum[1] = (A_ext[1] ^ B_ext[1]) ^ c1;
    assign sum[2] = (A_ext[2] ^ B_ext[2]) ^ c2;
    assign sum[3] = (A_ext[3] ^ B_ext[3]) ^ c3;
    assign sum[4] = (A_ext[4] ^ B_ext[4]) ^ c4; // Since A_ext[4]=0 and B_ext[4]=0, sum[4] = c4 (the final carry-out)

endmodule