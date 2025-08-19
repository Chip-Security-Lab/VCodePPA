module kogge_stone_adder(
    input [3:0] a,b,
    output [3:0] sum
);
    wire [3:0] p = a ^ b;
    wire [3:0] g = a & b;
    
    // Prefix tree
    wire [3:0] g1,p1,g2,p2;
    
    // First level
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    assign {g1[3:1],p1[3:1]} = {g[3:1] | (p[3:1] & g[2:0]), 
                              p[3:1] & p[2:0]};
    
    // Second level
    assign g2 = g1 | (p1 & {4{g1[3]}});
    assign p2 = p1 & {4{p1[3]}};
    
    // Final carries
    wire [4:0] c = {g2,1'b0} | {p2,1'b0};
    
    assign sum = p ^ c[3:0];
endmodule