//SystemVerilog
// 顶层模块
module Param_AND #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_a,
    input [WIDTH-1:0] data_b,
    output [WIDTH-1:0] result
);
    // 内部连线
    wire [WIDTH-1:0] negated_b;
    wire [WIDTH:0] partial_sum;
    
    // 数据预处理子模块
    Data_Preprocessor #(
        .WIDTH(WIDTH)
    ) preprocessor_inst (
        .data_b(data_b),
        .negated_b(negated_b),
        .initial_carry(partial_sum[0])
    );
    
    // 条件求和计算子模块
    Conditional_Sum_Calculator #(
        .WIDTH(WIDTH)
    ) calculator_inst (
        .data_a(data_a),
        .negated_b(negated_b),
        .partial_sum_in(partial_sum[0]),
        .partial_sum_out(partial_sum[WIDTH:1])
    );
    
    // 结果处理子模块
    Result_Handler #(
        .WIDTH(WIDTH)
    ) result_handler_inst (
        .partial_sum(partial_sum[WIDTH:1]),
        .result(result)
    );
    
endmodule

// 数据预处理子模块
module Data_Preprocessor #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_b,
    output [WIDTH-1:0] negated_b,
    output initial_carry
);
    // 取反data_b
    assign negated_b = ~data_b;
    // 初始进位设为1（减法补码操作）
    assign initial_carry = 1'b1;
    
endmodule

// 条件求和计算子模块
module Conditional_Sum_Calculator #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_a,
    input [WIDTH-1:0] negated_b,
    input partial_sum_in,
    output [WIDTH-1:0] partial_sum_out
);
    wire [WIDTH:0] partial_sum;
    wire [WIDTH-1:0] borrow;
    
    assign partial_sum[0] = partial_sum_in;
    
    // 逐位生成借位和结果
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : subtract_loop
            assign partial_sum[i+1] = data_a[i] + negated_b[i] + partial_sum[i];
            assign borrow[i] = ~partial_sum[i+1];
            // 在减法条件求和中，结果是部分和的低位
        end
    endgenerate
    
    // 输出部分和的高位部分
    assign partial_sum_out = partial_sum[WIDTH:1];
    
endmodule

// 结果处理子模块
module Result_Handler #(parameter WIDTH=8) (
    input [WIDTH-1:0] partial_sum,
    output [WIDTH-1:0] result
);
    // 最终结果直接来自部分和
    assign result = partial_sum;
    
endmodule