module subtractor_signed_overflow_8bit (
    input signed [7:0] a,
    input signed [7:0] b,
    output signed [7:0] diff,
    output overflow
);
    wire [7:0] b_neg;
    wire [8:0] sum;
    
    assign b_neg = ~b + 1'b1;
    assign sum = {a[7], a} + {b_neg[7], b_neg};
    assign diff = sum[7:0];
    assign overflow = sum[8] ^ sum[7];
endmodule