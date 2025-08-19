module subtractor_overflow_8bit (
    input [7:0] a, 
    input [7:0] b, 
    output [7:0] diff, 
    output overflow
);
    assign diff = a - b;
    assign overflow = (a[7] & ~b[7] & ~diff[7]) | (~a[7] & b[7] & diff[7]);
endmodule
