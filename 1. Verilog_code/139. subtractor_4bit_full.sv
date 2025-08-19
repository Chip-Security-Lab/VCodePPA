module subtractor_4bit_full (
    input [3:0] a, 
    input [3:0] b, 
    output [3:0] diff, 
    output borrow
);
    wire [3:0] b_complement;
    wire [4:0] sum;
    
    // Compute two's complement of b
    assign b_complement = ~b;
    
    // Perform a + (~b + 1) which is equivalent to a - b
    assign sum = {1'b0, a} + {1'b0, b_complement} + 5'b00001;
    
    // Extract the difference and borrow
    assign diff = sum[3:0];
    assign borrow = ~sum[4];
endmodule