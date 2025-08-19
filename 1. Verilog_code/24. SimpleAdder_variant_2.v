module Adder_2(
    input [3:0] A,
    input [3:0] B,
    output reg [4:0] sum
);

    // Declare intermediate signals for Carry-Lookahead Adder
    wire [3:0] P; // Propagate signals: Pi = Ai ^ Bi
    wire [3:0] G; // Generate signals: Gi = Ai & Bi
    wire [3:0] C_in; // Carry-in to each bit position (C_in[0] is cin, C_in[1] is carry_out_bit0 etc)
    wire cout; // Carry out of bit 3 (sum[4])

    wire cin = 1'b0; // Initial carry-in is 0 for A+B operation

    // Calculate P and G for each bit
    assign P = A ^ B;
    assign G = A & B;

    // Calculate carries using true Carry-Lookahead logic
    // C_in[i] is the carry into bit i
    // C_in[0] is the external cin
    // C_in[1] is carry out of bit 0 = G0 + P0.C_in[0]
    // C_in[2] is carry out of bit 1 = G1 + P1.C_in[1] = G1 + P1.G0 + P1.P0.C_in[0]
    // C_in[3] is carry out of bit 2 = G2 + P2.C_in[2] = G2 + P2.(G1 + P1.G0 + P1.P0.C_in[0])
    // cout is carry out of bit 3 = G3 + P3.C_in[3] = G3 + P3.(G2 + P2.G1 + P2.P1.G0 + P2.P1.P0.C_in[0])

    // With cin = 0:
    assign C_in[0] = cin; // C_in[0] = 0
    assign C_in[1] = G[0];
    assign C_in[2] = G[1] | (P[1] & G[0]);
    assign C_in[3] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]);
    assign cout    = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]);

    // Calculate sum bits and combine with carry out
    // sum[i] = P[i] ^ C_in[i]
    always @* begin
        sum[0] = P[0] ^ C_in[0];
        sum[1] = P[1] ^ C_in[1];
        sum[2] = P[2] ^ C_in[2];
        sum[3] = P[3] ^ C_in[3];
        sum[4] = cout; // The most significant bit is the final carry out
    end

endmodule