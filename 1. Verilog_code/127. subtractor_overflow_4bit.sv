module subtractor_overflow_4bit (
    input [3:0] a, 
    input [3:0] b, 
    output [3:0] diff, 
    output overflow
);
    assign diff = a - b;
    assign overflow = (a[3] & ~b[3] & ~diff[3]) | (~a[3] & b[3] & diff[3]);
endmodule
