module subtractor_signed_check_4bit (
    input signed [3:0] a, 
    input signed [3:0] b, 
    output signed [3:0] diff, 
    output negative
);
    assign diff = a - b;
    assign negative = (diff[3] == 1);  // 如果最高位为1，表示负数
endmodule
