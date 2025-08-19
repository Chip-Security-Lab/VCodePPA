module subtractor_signed_4bit (
    input signed [3:0] a, 
    input signed [3:0] b, 
    output signed [3:0] diff
);
    assign diff = a - b;  // 直接减法，适用于有符号数
endmodule
