module Sub5(
    input [3:0] A,
    input [3:0] B,
    output [3:0] D,
    output Bout
);

    wire [3:0] neg_B;
    wire [3:0] G, P;
    wire [4:0] C;
    
    Negate negate_inst(
        .in(B),
        .out(neg_B)
    );
    
    // 生成和传播信号
    assign G = A & neg_B;
    assign P = A ^ neg_B;
    
    // 进位链计算
    assign C[0] = 1'b1;
    assign C[1] = G[0] | (P[0] & C[0]);
    assign C[2] = G[1] | (P[1] & G[0]) | (P[1] & P[0] & C[0]);
    assign C[3] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & C[0]);
    assign C[4] = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]) | (P[3] & P[2] & P[1] & P[0] & C[0]);
    
    // 和计算
    assign D = P ^ C[3:0];
    assign Bout = C[4];

endmodule

module Negate(
    input [3:0] in,
    output [3:0] out
);
    assign out = ~in;
endmodule