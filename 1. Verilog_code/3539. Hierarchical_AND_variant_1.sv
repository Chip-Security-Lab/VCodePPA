//SystemVerilog
// 顶层模块
module Hierarchical_AND(
    input [1:0] in1, in2,
    output [3:0] res
);
    wire [1:0] and_results;
    
    // 实例化2位与门阵列子模块
    AND_Array_2bit and_array_inst(
        .operand_a(in1),
        .operand_b(in2),
        .result(and_results)
    );
    
    // 实例化结果格式化模块
    Result_Formatter formatter_inst(
        .and_results(and_results),
        .formatted_output(res)
    );
endmodule

// 2位与门阵列子模块 - 循环展开版本
module AND_Array_2bit(
    input [1:0] operand_a, operand_b,
    output [1:0] result
);
    // 循环展开，用独立实例替代genvar循环
    AND_Basic and_inst_0(
        .a(operand_a[0]),
        .b(operand_b[0]),
        .y(result[0])
    );
    
    AND_Basic and_inst_1(
        .a(operand_a[1]),
        .b(operand_b[1]),
        .y(result[1])
    );
endmodule

// 结果格式化模块
module Result_Formatter(
    input [1:0] and_results,
    output [3:0] formatted_output
);
    // 组合低2位的计算结果和高2位的固定值
    assign formatted_output = {2'b00, and_results};
endmodule

// 基本与门模块
module AND_Basic(
    input a, b,
    output y
);
    // 与门实现
    assign y = a & b;
endmodule