//SystemVerilog
`timescale 1ns / 1ps
module xor2_9 (
    input wire A, B,
    output wire Y
);
    // 使用移位减法除法器算法实现2位除法
    reg [1:0] quotient;
    reg [1:0] dividend;
    reg [1:0] divisor;
    reg [2:0] partial_remainder;
    
    always @(*) begin
        // 初始化操作数
        dividend = {A, 1'b0};
        divisor = {B, 1'b0};
        
        // 初始化部分余数和商
        partial_remainder = {1'b0, dividend};
        quotient = 2'b00;
        
        // 第一次迭代
        if (partial_remainder[2:1] >= divisor) begin
            partial_remainder[2:1] = partial_remainder[2:1] - divisor;
            quotient[1] = 1'b1;
        end
        
        // 第二次迭代
        partial_remainder = {partial_remainder[1:0], 1'b0};
        if (partial_remainder[2:1] >= divisor) begin
            partial_remainder[2:1] = partial_remainder[2:1] - divisor;
            quotient[0] = 1'b1;
        end
    end
    
    // 输出结果 - 保持功能等效性
    assign Y = quotient[1] ^ quotient[0];
endmodule