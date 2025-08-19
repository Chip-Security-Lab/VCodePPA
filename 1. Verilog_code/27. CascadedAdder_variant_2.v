module Adder_5(
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);

    // Wires for generate and propagate signals
    wire [3:0] p; // Propagate: A[i] ^ B[i]
    wire [3:0] g; // Generate: A[i] & B[i]

    // Wires for prefix generate and propagate signals
    // Stage 1 (step=1)
    wire [3:0] G1, P1;
    // Stage 2 (step=2)
    wire [3:0] G2, P2;

    // Wires for carries (c[i] is carry *into* bit i)
    // c[0] is cin (0), c[1]..c[4] are carries into bits 1..4
    wire [4:0] c;

    // Stage 0: Initial generate and propagate
    assign p[3:0] = A[3:0] ^ B[3:0];
    assign g[3:0] = A[3:0] & B[3:0];

    // Initial carry-in
    assign c[0] = 1'b0;

    // Stage 1: Prefix computation (step = 1)
    // i=0
    assign P1[0] = p[0];
    assign G1[0] = g[0];
    // i=1
    assign P1[1] = p[1] & p[0];
    assign G1[1] = g[1] | (p[1] & g[0]);
    // i=2
    assign P1[2] = p[2] & p[1];
    assign G1[2] = g[2] | (p[2] & g[1]);
    // i=3
    assign P1[3] = p[3] & p[2];
    assign G1[3] = g[3] | (p[3] & g[2]);

    // Stage 2: Prefix computation (step = 2)
    // i=0,1 (indices < step)
    assign P2[0] = P1[0];
    assign G2[0] = G1[0];
    assign P2[1] = P1[1];
    assign G2[1] = G1[1];
    // i=2 (index >= step)
    assign P2[2] = P1[2] & P1[0];
    assign G2[2] = G1[2] | (P1[2] & G1[0]);
    // i=3 (index >= step)
    assign P2[3] = P1[3] & P1[1];
    assign G2[3] = G1[3] | (P1[3] & G1[1]);

    // Carry computation (c[i] is carry *into* bit i)
    assign c[1] = G2[0]; // Carry into bit 1 is G up to bit 0
    assign c[2] = G2[1]; // Carry into bit 2 is G up to bit 1
    assign c[3] = G2[2]; // Carry into bit 3 is G up to bit 2
    assign c[4] = G2[3]; // Carry into bit 4 (final carry-out) is G up to bit 3

    // Sum computation
    assign sum[0] = p[0] ^ c[0]; // sum[0] = p[0] ^ 0 = p[0]
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign sum[3] = p[3] ^ c[3];
    assign sum[4] = c[4]; // Final carry-out is the MSB of sum

endmodule