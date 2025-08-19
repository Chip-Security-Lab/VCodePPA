module unsigned_subtractor_4bit (
    input [3:0] a,
    input [3:0] b,
    output [3:0] diff
);

    // Simplified carry computation
    wire [3:0] carry;
    
    // Optimized carry computation using simplified Boolean expressions
    assign carry[0] = 1'b0;  // Initial carry-in is 0 for subtraction
    
    // Simplified carry expressions using Boolean algebra
    assign carry[1] = a[0] & b[0];
    
    assign carry[2] = (a[1] & b[1]) | 
                      ((a[1] ^ b[1]) & (a[0] & b[0]));
    
    assign carry[3] = (a[2] & b[2]) | 
                      ((a[2] ^ b[2]) & (a[1] & b[1])) |
                      ((a[2] ^ b[2]) & (a[1] ^ b[1]) & (a[0] & b[0]));
    
    // Difference computation
    assign diff = a ^ b ^ {carry[2:0], 1'b0};

endmodule