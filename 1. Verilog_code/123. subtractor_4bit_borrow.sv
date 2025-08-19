module subtractor_4bit_borrow (
    input [3:0] a, 
    input [3:0] b, 
    output [3:0] diff, 
    output borrow
);
    assign {borrow, diff} = a - b;  // 包含借位的运算
endmodule
