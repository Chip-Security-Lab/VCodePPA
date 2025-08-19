module Adder_9(
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);

    // Internal signals for Propagate and Generate
    wire [3:0] p; // p[i] = A[i] ^ B[i]
    wire [3:0] g; // g[i] = A[i] & B[i]

    // Internal signals for carries
    wire [4:0] c; // c[i] is the carry into bit i (c[0] is Cin)

    // 1. Generate P and G for each bit
    assign p = A ^ B;
    assign g = A & B;

    // Input carry
    assign c[0] = 1'b0; // For A + B, Cin is 0

    // 2. Compute Carries using expanded boolean expressions (Carry Lookahead)
    // c[i] = G[i-1:0] | (P[i-1:0] & c[0])
    // Since c[0] = 0, c[i] = G[i-1:0]
    // G[i:j] = G[i:k] | (P[i:k] & G[k-1:j])
    // P[i:j] = P[i:k] & P[k-1:j]
    // G[i:i] = g[i], P[i:i] = p[i]

    assign c[1] = g[0];
    assign c[2] = g[1] | (p[1] & g[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);

    // 3. Compute Sum bits
    // sum[i] = p[i] ^ c[i]
    assign sum[0] = p[0] ^ c[0]; // p[0] ^ 0 = p[0]
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign sum[3] = p[3] ^ c[3];
    assign sum[4] = c[4]; // Carry out is the 5th bit of the sum

endmodule