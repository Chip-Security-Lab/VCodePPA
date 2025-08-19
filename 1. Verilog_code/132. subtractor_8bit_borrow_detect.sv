module subtractor_8bit_borrow_detect (
    input [7:0] a, 
    input [7:0] b, 
    output [7:0] diff, 
    output borrow
);
    assign {borrow, diff} = a - b;
endmodule
