module subtractor_8bit_negative (
    input [7:0] a, 
    input [7:0] b, 
    output [7:0] diff
);
    assign diff = a + (-b);  // 通过加上负数来实现减法
endmodule
