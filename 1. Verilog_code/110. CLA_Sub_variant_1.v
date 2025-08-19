module CLA_Sub(
    input  [3:0] A,
    input  [3:0] B,
    output [3:0] D,
    output       Bout
);

    // Generate and propagate signals
    wire [3:0] G = A & ~B;
    wire [3:0] P = A ^ ~B;
    
    // Optimized carry lookahead logic
    wire [4:0] C;
    assign C[0] = 1'b1;
    assign C[1] = G[0] | (P[0] & C[0]);
    assign C[2] = G[1] | (P[1] & C[1]);
    assign C[3] = G[2] | (P[2] & C[2]);
    assign C[4] = G[3] | (P[3] & C[3]);
    
    // Sum calculation
    assign D = P ^ C[3:0];
    assign Bout = C[4];

endmodule