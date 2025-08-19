module CLA_Sub(input [3:0] A, B, output [3:0] D, Bout);
    wire [3:0] B_comp = ~B;
    wire [3:0] P, G;
    wire [3:0] G1, P1;
    wire [3:0] G2, P2;
    wire [3:0] G3, P3;
    wire [4:0] C;
    
    // Generate and Propagate
    assign P = A ^ B_comp;
    assign G = A & B_comp;
    
    // First level - optimized using Boolean algebra
    assign G1[0] = G[0];
    assign P1[0] = P[0];
    assign G1[1] = G[1] | (P[1] & G[0]);
    assign P1[1] = P[1] & P[0];
    assign G1[2] = G[2] | (P[2] & G[1]);
    assign P1[2] = P[2] & P[1];
    assign G1[3] = G[3] | (P[3] & G[2]);
    assign P1[3] = P[3] & P[2];
    
    // Second level - optimized using Boolean algebra
    assign G2[0] = G1[0];
    assign P2[0] = P1[0];
    assign G2[1] = G1[1];
    assign P2[1] = P1[1];
    assign G2[2] = G1[2] | (P1[2] & G1[0]);
    assign P2[2] = P1[2] & P1[0];
    assign G2[3] = G1[3] | (P1[3] & G1[1]);
    assign P2[3] = P1[3] & P1[1];
    
    // Third level - optimized using Boolean algebra
    assign G3[0] = G2[0];
    assign P3[0] = P2[0];
    assign G3[1] = G2[1];
    assign P3[1] = P2[1];
    assign G3[2] = G2[2];
    assign P3[2] = P2[2];
    assign G3[3] = G2[3] | (P2[3] & G2[0]);
    assign P3[3] = P2[3] & P2[0];
    
    // Carry computation - optimized
    assign C[0] = 1'b1;
    assign C[1] = G3[0];
    assign C[2] = G3[1];
    assign C[3] = G3[2];
    assign C[4] = G3[3];
    
    // Sum computation - optimized
    assign D = P ^ C[3:0];
    assign Bout = C[4];
endmodule