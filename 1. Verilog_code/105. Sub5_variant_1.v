module Sub5(input [3:0] A, B, output [3:0] D, output Bout);
    wire [3:0] B_inv = ~B;
    wire [3:0] p = A ^ B_inv;
    wire [3:0] g = A & B_inv;
    
    wire [3:0] c;
    wire [3:0] pg;
    
    // Optimized carry computation using parallel prefix
    assign pg[0] = p[0];
    assign pg[1] = p[1] & p[0];
    assign pg[2] = p[2] & p[1] & p[0];
    assign pg[3] = p[3] & p[2] & p[1] & p[0];
    
    assign c[0] = 1'b1;
    assign c[1] = g[0] | (pg[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (pg[1] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (pg[2] & c[0]);
    assign Bout = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (pg[3] & c[0]);
    
    assign D = p ^ c[3:0];
endmodule