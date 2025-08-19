module Adder_2(
    input wire [3:0] A,
    input wire [3:0] B,
    output reg [4:0] sum
);

    // Pre-processing
    wire [3:0] g; // Generate signals: gi = Ai & Bi
    wire [3:0] p; // Propagate signals: pi = Ai ^ Bi
    assign g = A & B;
    assign p = A ^ B;

    // Parallel Prefix Computation (Han-Carlson Structure for N=4)

    // Layer 1: Distance 1 (Black cells)
    // N(i,1) = N(i,0) . N(i-1,0) for i=1..3
    wire [3:1] G1;
    wire [3:1] P1;
    assign G1[1] = g[1] | (p[1] & g[0]);
    assign P1[1] = p[1] & p[0];
    assign G1[2] = g[2] | (p[2] & g[1]);
    assign P1[2] = p[2] & p[1];
    assign G1[3] = g[3] | (p[3] & g[2]);
    assign P1[3] = p[3] & p[2];

    // Layer 2: Distance 2 (Gray/Black cells)
    // N(i,2) = N(i,1) . N(i-2,0) for i=2 (Gray cell)
    // N(i,2) = N(i,1) . N(i-2,1) for i=3 (Black cell)
    wire [3:2] G2;
    wire [3:2] P2;
    assign G2[2] = G1[2] | (P1[2] & g[0]); // Gray cell (2,1) . (0,0)
    assign P2[2] = P1[2] & p[0];
    assign G2[3] = G1[3] | (P1[3] & G1[1]); // Black cell (3,1) . (1,1)
    assign P2[3] = P1[3] & P1[1];

    // Final Prefix Generates G_prefix[i] = G[i:0]
    wire [3:0] G_prefix;
    assign G_prefix[0] = g[0];
    assign G_prefix[1] = G1[1];
    assign G_prefix[2] = G2[2];
    assign G_prefix[3] = G2[3];

    // Carry Computation (C[i] is carry *into* bit i)
    // C[0] = Carry-in (assumed 0)
    // C[i] = G[i-1:0] for i > 0
    wire [4:0] C;
    assign C[0] = 1'b0; // Carry-in
    assign C[1] = G_prefix[0]; // Carry into bit 1 comes from G[0:0]
    assign C[2] = G_prefix[1]; // Carry into bit 2 comes from G[1:0]
    assign C[3] = G_prefix[2]; // Carry into bit 3 comes from G[2:0]
    assign C[4] = G_prefix[3]; // Carry into bit 4 (Carry-out) comes from G[3:0]

    // Sum Computation
    // sum[i] = pi ^ Ci for i=0..3
    // sum[4] = C4 (Carry-out)
    always @* begin
        sum[0] = p[0] ^ C[0];
        sum[1] = p[1] ^ C[1];
        sum[2] = p[2] ^ C[2];
        sum[3] = p[3] ^ C[3];
        sum[4] = C[4]; // Carry-out
    end

endmodule