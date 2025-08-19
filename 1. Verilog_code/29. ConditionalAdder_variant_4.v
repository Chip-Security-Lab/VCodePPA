module Adder_7(
    input [3:0] A,
    input [3:0] B,
    output reg [4:0] sum
);

    // Internal signals for Han-Carlson Adder
    wire [3:0] p; // Propagate signals: pi = Ai ^ Bi
    wire [3:0] g; // Generate signals: gi = Ai & Bi

    // Han-Carlson prefix network intermediate signals
    // Level 1 (groups of 2)
    wire [1:0] hc_p1; // Group propagate P[1:0], P[3:2]
    wire [1:0] hc_g1; // Group generate G[1:0], G[3:2]

    // Level 2 (group of 4)
    wire hc_p2; // Group propagate P[3:0]
    wire hc_g2; // Group generate G[3:0]

    wire [4:0] c; // Carry signals: c[0] is input carry, c[1..4] are internal carries
    wire [3:0] s; // Sum bits before final carry: si = pi ^ ci

    // 1. Pre-processing: Calculate bit-wise propagate and generate signals
    assign p = A ^ B;
    assign g = A & B;

    // Carry-in for the least significant bit (LSB) is 0 for simple addition A + B
    assign c[0] = 1'b0;

    // 2. Parallel Prefix Network (Han-Carlson structure)
    // Level 1 computation (groups of 2)
    // Group [1:0]: (G[1:0], P[1:0]) = combine((g[1], p[1]), (g[0], p[0]))
    assign hc_p1[0] = p[1] & p[0];
    assign hc_g1[0] = g[1] | (p[1] & g[0]);

    // Group [3:2]: (G[3:2], P[3:2]) = combine((g[3], p[3]), (g[2], p[2]))
    assign hc_p1[1] = p[3] & p[2];
    assign hc_g1[1] = g[3] | (p[3] & g[2]);

    // Level 2 computation (group of 4)
    // Group [3:0]: (G[3:0], P[3:0]) = combine((G[3:2], P[3:2]), (G[1:0], P[1:0]))
    assign hc_p2 = hc_p1[1] & hc_p1[0];
    assign hc_g2 = hc_g1[1] | (hc_p1[1] & hc_g1[0]);

    // 3. Carry Generation using prefix results (c[i] is carry *into* bit i)
    // c[1] = g[0] | (p[0] & c[0])
    assign c[1] = g[0]; // Since c[0] = 0

    // c[2] = G[1:0] | (P[1:0] & c[0])
    assign c[2] = hc_g1[0]; // Since c[0] = 0

    // c[3] = G[2:0] | (P[2:0] & c[0])
    // G[2:0] = combine((g[2], p[2]), (G[1:0], P[1:0])).G = g[2] | (p[2] & G[1:0])
    // P[2:0] = combine((g[2], p[2]), (G[1:0], P[1:0])).P = p[2] & P[1:0]
    assign c[3] = g[2] | (p[2] & hc_g1[0]); // Since c[0] = 0

    // c[4] = G[3:0] | (P[3:0] & c[0])
    assign c[4] = hc_g2; // Since c[0] = 0

    // 4. Sum bit generation
    // si = pi ^ ci
    assign s[0] = p[0] ^ c[0]; // s[0] = p[0] ^ 0 = p[0]
    assign s[1] = p[1] ^ c[1];
    assign s[2] = p[2] ^ c[2];
    assign s[3] = p[3] ^ c[3];

    // Combine the carry-out (c[4]) and sum bits (s[3:0]) for the final result
    // Using always @* for combinational assignment to match original style
    always @* begin
        sum[4]   = c[4];   // The most significant bit is the final carry-out
        sum[3:0] = s[3:0]; // The lower bits are the sum bits
    end

endmodule