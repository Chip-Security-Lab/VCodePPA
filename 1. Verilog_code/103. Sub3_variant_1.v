module Sub3 #(parameter W=8)(
    input [W-1:0] a,
    input [W-1:0] b,
    output [W-1:0] res
);

    wire [W-1:0] borrow;
    wire [W-1:0] diff;
    
    // Generate borrow signals
    assign borrow[0] = ~a[0] & b[0];
    assign diff[0] = a[0] ^ b[0];
    
    genvar i;
    generate
        for(i=1; i<W; i=i+1) begin: carry_lookahead
            // Simplified borrow expression using De Morgan's law
            assign borrow[i] = (~a[i] & b[i]) | (a[i] & ~b[i] & borrow[i-1]);
            assign diff[i] = a[i] ^ b[i] ^ borrow[i-1];
        end
    endgenerate
    
    assign res = diff;

endmodule