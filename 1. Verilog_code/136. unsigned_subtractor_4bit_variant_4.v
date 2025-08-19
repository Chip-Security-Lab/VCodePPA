module unsigned_subtractor_4bit (
    input [3:0] a,
    input [3:0] b,
    output [3:0] diff
);

    wire [3:0] b_comp = ~b;
    wire [3:0] g = a & b_comp;
    wire [3:0] p = a ^ b_comp;
    
    wire [3:0] carry;
    assign carry[0] = g[0];
    assign carry[1] = g[1] | (p[1] & g[0]);
    assign carry[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
    assign carry[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
    
    assign diff = p ^ {1'b0, carry[2:0]};

endmodule