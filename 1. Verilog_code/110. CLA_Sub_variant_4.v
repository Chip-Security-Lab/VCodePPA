module CLA_Sub(input [3:0] A, B, output [3:0] D, Bout);
    // Optimized carry-lookahead subtractor implementation
    wire [3:0] B_comp = ~B;
    wire [3:0] g = A & B_comp;
    wire [3:0] p = A ^ B_comp;
    
    // Optimized prefix computation
    wire [1:0] g_01 = {g[1], g[0]};
    wire [1:0] p_01 = {p[1], p[0]};
    wire [1:0] g_23 = {g[3], g[2]};
    wire [1:0] p_23 = {p[3], p[2]};
    
    // Parallel carry computation
    wire c0 = 1'b1;
    wire c1 = g[0] | (p[0] & c0);
    wire c2 = g[1] | (p[1] & c1);
    wire c3 = g[2] | (p[2] & c2);
    wire c4 = g[3] | (p[3] & c3);
    
    // Optimized sum and borrow computation
    assign D = p ^ {c3, c2, c1, c0};
    assign Bout = c4;
endmodule