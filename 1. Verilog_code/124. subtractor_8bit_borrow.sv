module subtractor_8bit_borrow (
    input [7:0] a, 
    input [7:0] b, 
    output [7:0] diff, 
    output borrow
);
    assign {borrow, diff} = a - b;  // 包含借位
endmodule
