module subtractor_signed_overflow_8bit (
    input signed [7:0] a, 
    input signed [7:0] b, 
    output signed [7:0] diff, 
    output overflow
);
    assign diff = a - b;
    assign overflow = (a[7] & ~b[7] & ~diff[7]) | (~a[7] & b[7] & diff[7]);
endmodule
