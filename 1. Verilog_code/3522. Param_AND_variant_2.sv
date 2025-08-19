//SystemVerilog
// 顶层模块
module Param_AND #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_a,
    input [WIDTH-1:0] data_b,
    output [WIDTH-1:0] result
);
    // 内部连线
    wire [WIDTH-1:0] processed_data_a;
    wire [WIDTH-1:0] processed_data_b;
    wire [WIDTH-1:0] operation_result;
    
    // 输入处理子模块实例化
    Input_Processor #(
        .WIDTH(WIDTH)
    ) input_proc (
        .in_a(data_a),
        .in_b(data_b),
        .out_a(processed_data_a),
        .out_b(processed_data_b)
    );
    
    // 减法运算子模块实例化
    Subtractor_Operation #(
        .WIDTH(WIDTH)
    ) sub_op (
        .op_a(processed_data_a),
        .op_b(processed_data_b),
        .result(operation_result)
    );
    
    // 输出处理子模块实例化
    Output_Processor #(
        .WIDTH(WIDTH)
    ) output_proc (
        .in_result(operation_result),
        .out_result(result)
    );
    
endmodule

// 输入处理子模块 - 负责输入信号的预处理
module Input_Processor #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] in_a,
    input [WIDTH-1:0] in_b,
    output [WIDTH-1:0] out_a,
    output [WIDTH-1:0] out_b
);
    // 简单传递，可以在此添加输入缓冲或预处理逻辑
    assign out_a = in_a;
    assign out_b = in_b;
endmodule

// 条件求和减法器子模块 - 使用条件求和算法实现减法
module Subtractor_Operation #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] op_a,
    input [WIDTH-1:0] op_b,
    output [WIDTH-1:0] result
);
    // 内部信号定义
    wire [WIDTH-1:0] not_b;
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] sum;
    
    // 对操作数b取反
    assign not_b = ~op_b;
    
    // 初始进位为1（用于二进制补码）
    assign carry[0] = 1'b1;
    
    // 条件求和减法实现 (a - b = a + ~b + 1)
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_csa
            // 计算每一位的和与进位
            assign sum[i] = op_a[i] ^ not_b[i] ^ carry[i];
            assign carry[i+1] = (op_a[i] & not_b[i]) | 
                               (op_a[i] & carry[i]) | 
                               (not_b[i] & carry[i]);
        end
    endgenerate
    
    // 结果赋值
    assign result = sum;
endmodule

// 输出处理子模块 - 负责输出信号的后处理
module Output_Processor #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] in_result,
    output [WIDTH-1:0] out_result
);
    // 简单传递，可以在此添加输出缓冲或后处理逻辑
    assign out_result = in_result;
endmodule