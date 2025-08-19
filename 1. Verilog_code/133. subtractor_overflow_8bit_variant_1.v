module subtractor_overflow_8bit (
    input [7:0] a,
    input [7:0] b,
    output [7:0] diff,
    output overflow
);
    // 计算b的补码
    wire [7:0] b_complement;
    wire [7:0] sum;
    wire carry_out;
    
    // 计算b的补码
    assign b_complement = ~b + 1'b1;
    
    // 使用补码加法实现减法
    assign {carry_out, sum} = a + b_complement;
    
    // 输出结果
    assign diff = sum;
    
    // 溢出检测
    assign overflow = (a[7] & b_complement[7] & ~sum[7]) | (~a[7] & ~b_complement[7] & sum[7]);
endmodule