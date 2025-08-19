//SystemVerilog
module parallel_prefix_subtractor (
    input [7:0] A,
    input [7:0] B,
    output [7:0] S,
    output borrow_out
);
    wire [7:0] P, G, C;
    wire [7:0] G1, P1;
    wire [7:0] G2, P2;
    wire [7:0] G3, P3;

    // First level
    assign P = A | B;
    assign G = A & ~B;

    // Second level (2-bit groups)
    assign G1[0] = G[0];
    assign P1[0] = P[0];
    assign G1[1] = G[1] | (P[1] & G[0]);
    assign P1[1] = P[1] & P[0];
    assign G1[2] = G[2];
    assign P1[2] = P[2];
    assign G1[3] = G[3] | (P[3] & G[2]);
    assign P1[3] = P[3] & P[2];
    assign G1[4] = G[4];
    assign P1[4] = P[4];
    assign G1[5] = G[5] | (P[5] & G[4]);
    assign P1[5] = P[5] & P[4];
    assign G1[6] = G[6];
    assign P1[6] = P[6];
    assign G1[7] = G[7] | (P[7] & G[6]);
    assign P1[7] = P[7] & P[6];

    // Third level (4-bit groups)
    assign G2[0] = G1[0];
    assign P2[0] = P1[0];
    assign G2[1] = G1[1];
    assign P2[1] = P1[1];
    assign G2[2] = G1[2] | (P1[2] & G1[0]);
    assign P2[2] = P1[2] & P1[0];
    assign G2[3] = G1[3] | (P1[3] & G1[1]);
    assign P2[3] = P1[3] & P1[1];
    assign G2[4] = G1[4];
    assign P2[4] = P1[4];
    assign G2[5] = G1[5];
    assign P2[5] = P1[5];
    assign G2[6] = G1[6] | (P1[6] & G1[4]);
    assign P2[6] = P1[6] & P1[4];
    assign G2[7] = G1[7] | (P1[7] & G1[5]);
    assign P2[7] = P1[7] & P1[5];

    // Fourth level (8-bit group)
    assign G3[0] = G2[0];
    assign P3[0] = P2[0];
    assign G3[1] = G2[1];
    assign P3[1] = P2[1];
    assign G3[2] = G2[2];
    assign P3[2] = P2[2];
    assign G3[3] = G2[3];
    assign P3[3] = P2[3];
    assign G3[4] = G2[4] | (P2[4] & G2[0]);
    assign P3[4] = P2[4] & P2[0];
    assign G3[5] = G2[5] | (P2[5] & G2[1]);
    assign P3[5] = P2[5] & P2[1];
    assign G3[6] = G2[6] | (P2[6] & G2[2]);
    assign P3[6] = P2[6] & P2[2];
    assign G3[7] = G2[7] | (P2[7] & G2[3]);
    assign P3[7] = P2[7] & P2[3];

    // Final carry computation
    assign C[0] = 1'b0;
    assign C[1] = G3[0];
    assign C[2] = G3[1];
    assign C[3] = G3[2];
    assign C[4] = G3[3];
    assign C[5] = G3[4];
    assign C[6] = G3[5];
    assign C[7] = G3[6];
    assign borrow_out = G3[7];

    // Subtraction result
    assign S = A ^ B ^ C;

endmodule