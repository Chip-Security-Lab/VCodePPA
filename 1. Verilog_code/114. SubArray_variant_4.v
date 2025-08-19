module SubArray(input [3:0] a, b, output [3:0] d);
    wire [3:0] b_comp;  // b的补码
    wire [3:0] sum;     // 补码加法结果
    
    // 计算b的补码
    assign b_comp = ~b + 1;
    
    // 使用补码加法实现减法
    assign sum = a + b_comp;
    
    // 输出结果
    assign d = sum;
endmodule