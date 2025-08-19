//SystemVerilog
`timescale 1ns/1ps

module Delay_XNOR(
    input wire a, b,
    output reg z
);
    // 使用带符号乘法算法实现XNOR功能
    reg signed [1:0] input_a, input_b;
    reg signed [3:0] mult_result;
    reg xnor_result;
    
    // 将输入扩展为带符号2位数
    always @(*) begin
        // 把单bit扩展为2bit带符号数
        input_a = {1'b0, a};
        input_b = {1'b0, b};
        
        // 使用乘法运算（两个相同的值乘积为正，不同为负）
        mult_result = (2'b01 - {1'b0, input_a[0]}) * (2'b01 - {1'b0, input_b[0]});
        
        // 从乘法结果获取XNOR结果
        // 当a和b相同时(00或11)，结果为1
        // 当a和b不同时(01或10)，结果为0
        xnor_result = (mult_result[0] == 1'b1);
    end
    
    // 应用延迟
    always @(*) begin
        #1.8 z = xnor_result;  // 1.8ns传输延迟
    end
    
endmodule