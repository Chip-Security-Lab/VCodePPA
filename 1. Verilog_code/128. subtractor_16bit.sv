module subtractor_16bit (
    input [15:0] a, 
    input [15:0] b, 
    output [15:0] diff
);
    assign diff = a - b;
endmodule
