module Adder_9(
    input [3:0] A,
    input [3:0] B,
    output reg [4:0] sum
);

    // Signals for Carry-Lookahead Adder
    wire [3:0] P; // Propagate: A[i] ^ B[i]
    wire [3:0] G; // Generate: A[i] & B[i]
    wire [4:0] C; // Carry: C[0] is carry-in (0), C[1..4] are carries into bits 1..4
    wire [3:0] S; // Sum bits: P[i] ^ C[i]

    // Calculate Propagate and Generate signals for each bit
    assign P = A ^ B;
    assign G = A & B;

    // Carry-in is 0 for simple addition (A + B)
    assign C[0] = 1'b0;

    // Calculate Carry signals using Carry-Lookahead logic
    // C[i+1] = G[i] | (P[i] & C[i]) -- Recursive form
    // Direct calculation from C[0]:
    // C1 = G0 | (P0 & C0)
    // C2 = G1 | (P1 & C1) = G1 | (P1 & (G0 | (P0 & C0))) = G1 | (P1 & G0) | (P1 & P0 & C0)
    // C3 = G2 | (P2 & C2) = G2 | (P2 & (G1 | (P1 & G0) | (P1 & P0 & C0))) = G2 | (P2 & G1) | (P2 & P1 & G0) | (P2 & P1 & P0 & C0)
    // C4 = G3 | (P3 & C3) = G3 | (P3 & (G2 | (P2 & G1) | (P2 & P1 & G0) | (P2 & P1 & P0 & C0))) = G3 | (P3 & G2) | (P3 & P2 & G1) | (P3 & P2 & P1 & G0) | (P3 & P2 & P1 & P0 & C0)

    // With C[0] = 0:
    assign C[1] = G[0];
    assign C[2] = G[1] | (P[1] & G[0]);
    assign C[3] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]);
    assign C[4] = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]);

    // Calculate Sum bits
    // S[i] = P[i] ^ C[i]
    assign S[0] = P[0] ^ C[0]; // S0 = P0 ^ 0 = P0
    assign S[1] = P[1] ^ C[1];
    assign S[2] = P[2] ^ C[2];
    assign S[3] = P[3] ^ C[3];

    // Combine carry-out (C[4]) and sum bits (S[3:0]) for the final result
    // The original logic was equivalent to sum = A + B, so we directly assign the CLA result.
    always @(*) begin
        sum = {C[4], S[3:0]};
    end

endmodule