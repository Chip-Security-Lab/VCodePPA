module subtractor_4bit_conditional (
    input [3:0] a,
    input [3:0] b,
    output [3:0] diff,
    output borrow
);
    wire [3:0] b_comp;
    wire [3:0] carry;
    
    // Simplified conditional inversion
    assign b_comp[0] = ~b[0];
    assign {carry[0], diff[0]} = a[0] + b_comp[0] + 1'b1;
    
    assign b_comp[1] = carry[0] ? b[1] : ~b[1];
    assign {carry[1], diff[1]} = a[1] + b_comp[1] + carry[0];
    
    assign b_comp[2] = carry[1] ? b[2] : ~b[2];
    assign {carry[2], diff[2]} = a[2] + b_comp[2] + carry[1];
    
    assign b_comp[3] = carry[2] ? b[3] : ~b[3];
    assign {carry[3], diff[3]} = a[3] + b_comp[3] + carry[2];
    
    assign borrow = carry[3];
endmodule