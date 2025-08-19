module subtractor_4bit_cascade (
    input [3:0] a, 
    input [3:0] b, 
    output [3:0] diff, 
    output borrow
);
    wire b0, b1, b2;
    assign {b0, diff[0]} = a[0] - b[0];
    assign {b1, diff[1]} = a[1] - b[1] - b0;
    assign {b2, diff[2]} = a[2] - b[2] - b1;
    assign {borrow, diff[3]} = a[3] - b[3] - b2;
endmodule
