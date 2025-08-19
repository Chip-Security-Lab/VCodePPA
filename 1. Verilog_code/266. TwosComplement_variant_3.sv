//SystemVerilog
// 顶层模块
module TwosComplement #(
    parameter WIDTH = 8
)(
    input signed [WIDTH-1:0] number,
    output [WIDTH-1:0] complement
);
    OptimizedComplementCalculator #(
        .WIDTH(WIDTH)
    ) optimized_complement_inst (
        .number(number),
        .complement(complement)
    );
endmodule

// 使用条件求和减法算法优化的补码计算模块
module OptimizedComplementCalculator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] number,
    output [WIDTH-1:0] complement
);
    wire [WIDTH-1:0] zeros;
    assign zeros = {WIDTH{1'b0}};
    
    // 使用条件求和减法算法实现二进制补码
    // 二进制补码等价于 0 - number
    ConditionalSumSubtractor #(
        .WIDTH(WIDTH)
    ) subtractor_inst (
        .minuend(zeros),
        .subtrahend(number),
        .difference(complement)
    );
endmodule

// 条件求和减法器模块
module ConditionalSumSubtractor #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] minuend,
    input [WIDTH-1:0] subtrahend,
    output [WIDTH-1:0] difference
);
    // 内部信号定义
    wire [WIDTH-1:0] inverted_subtrahend;
    wire [WIDTH:0] carry;
    
    assign carry[0] = 1'b1; // 初始进位设为1

    // 第一级 - 对被减数取反
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : subtrahend_inverter
            assign inverted_subtrahend[i] = ~subtrahend[i];
        end
    endgenerate
    
    // 第二级 - 条件求和减法实现
    genvar j;
    generate
        for (j = 0; j < WIDTH; j = j + 1) begin : subtractor_bits
            // 条件求和计算
            wire sum0, sum1;
            wire carry0, carry1;
            
            // 计算两种可能的和和进位
            assign sum0 = minuend[j] ^ inverted_subtrahend[j] ^ 1'b0;
            assign sum1 = minuend[j] ^ inverted_subtrahend[j] ^ 1'b1;
            
            assign carry0 = (minuend[j] & inverted_subtrahend[j]) | 
                           (minuend[j] & 1'b0) | 
                           (inverted_subtrahend[j] & 1'b0);
            
            assign carry1 = (minuend[j] & inverted_subtrahend[j]) | 
                           (minuend[j] & 1'b1) | 
                           (inverted_subtrahend[j] & 1'b1);
            
            // 根据前一位的进位选择正确的和
            assign difference[j] = (carry[j]) ? sum1 : sum0;
            
            // 更新进位
            assign carry[j+1] = (carry[j]) ? carry1 : carry0;
        end
    endgenerate
endmodule