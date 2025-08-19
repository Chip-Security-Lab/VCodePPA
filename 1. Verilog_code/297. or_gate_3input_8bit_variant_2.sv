//SystemVerilog
// 顶层模块 - 连接各个子模块
module or_gate_3input_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [7:0] c,
    output wire [7:0] y
);
    // 内部连线
    wire [7:0] ab_result;
    
    // 实例化第一级或运算子模块
    or_operation_2input #(
        .WIDTH(8)
    ) first_or_stage (
        .operand_a(a),
        .operand_b(b),
        .result(ab_result)
    );
    
    // 实例化第二级或运算子模块
    or_operation_2input #(
        .WIDTH(8)
    ) second_or_stage (
        .operand_a(ab_result),
        .operand_b(c),
        .result(y)
    );
endmodule

// 参数化的2输入或运算子模块
module or_operation_2input #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] operand_a,
    input  wire [WIDTH-1:0] operand_b,
    output wire [WIDTH-1:0] result
);
    // 使用生成块以实现更好的性能和面积优化
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : or_bit
            // 位级或操作可以更好地映射到FPGA/ASIC资源
            assign result[i] = operand_a[i] | operand_b[i];
        end
    endgenerate
endmodule