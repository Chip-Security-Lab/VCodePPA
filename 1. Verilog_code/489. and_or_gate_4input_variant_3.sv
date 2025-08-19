//SystemVerilog
// 顶层模块
module and_or_gate_4input (
    input wire A, B, C, D,   // 四个输入
    output wire Y            // 输出Y
);
    // 内部连线
    wire AB, CD;
    
    // 实例化逻辑计算子模块
    logic_computation logic_comp_inst (
        .input_a(A),
        .input_b(B),
        .input_c(C),
        .input_d(D),
        .and_result1(AB),
        .and_result2(CD),
        .final_result(Y)
    );
endmodule

// 逻辑计算子模块，整合了与门和或门操作
module logic_computation (
    input wire input_a, input_b, input_c, input_d,
    output wire and_result1, and_result2, final_result
);
    // 实例化与门阵列子模块
    and_gate_array and_gates_inst (
        .a1(input_a),
        .a2(input_b),
        .b1(input_c),
        .b2(input_b),
        .y1(and_result1),
        .y2(and_result2)
    );
    
    // 实例化或门子模块，优化版本
    or_gate_optimized or_gate_inst (
        .a(and_result1),
        .b(and_result2),
        .y(final_result)
    );
endmodule

// 与门阵列子模块，优化多个与门操作
module and_gate_array (
    input wire a1, a2, b1, b2,
    output wire y1, y2
);
    // 参数化延迟，更精确的时序控制
    parameter AND_DELAY = 0.8;
    
    // 并行计算两个与门结果
    assign #(AND_DELAY) y1 = a1 & a2;
    assign #(AND_DELAY) y2 = b1 & b2;
endmodule

// 优化的或门子模块
module or_gate_optimized (
    input wire a, b,
    output wire y
);
    // 优化后的延迟参数
    parameter OR_DELAY = 0.7;
    
    // 使用优化的或运算
    assign #(OR_DELAY) y = a | b;
endmodule