//SystemVerilog
module Hierarchical_XNOR(
    input [1:0] a, b,
    output [3:0] result
);
    wire [1:0] xnor_result;
    
    // 实例化XNOR逻辑子模块
    XNOR_Logic xnor_logic_inst (
        .a(a),
        .b(b),
        .result(xnor_result)
    );
    
    // 实例化结果组合子模块
    Result_Combiner result_combiner_inst (
        .xnor_result(xnor_result),
        .full_result(result)
    );
endmodule

// 专门处理XNOR逻辑的子模块
module XNOR_Logic (
    input [1:0] a,
    input [1:0] b,
    output [1:0] result
);
    // 使用布尔代数恒等式实现: ~(a ^ b) = (a & b) | (~a & ~b)
    wire [1:0] and_result;
    wire [1:0] nor_result;
    wire [1:0] not_a;
    wire [1:0] not_b;
    
    // 计算a与b的与操作
    And_Operation and_op (
        .in1(a),
        .in2(b),
        .out(and_result)
    );
    
    // 计算~a与~b的与操作
    Not_Operation not_a_op (
        .in(a),
        .out(not_a)
    );
    
    Not_Operation not_b_op (
        .in(b),
        .out(not_b)
    );
    
    And_Operation nor_op (
        .in1(not_a),
        .in2(not_b),
        .out(nor_result)
    );
    
    // 合并结果
    Or_Operation or_op (
        .in1(and_result),
        .in2(nor_result),
        .out(result)
    );
endmodule

// 基本的与操作子模块
module And_Operation (
    input [1:0] in1,
    input [1:0] in2,
    output [1:0] out
);
    assign out = in1 & in2;
endmodule

// 基本的或操作子模块
module Or_Operation (
    input [1:0] in1,
    input [1:0] in2,
    output [1:0] out
);
    assign out = in1 | in2;
endmodule

// 基本的非操作子模块
module Not_Operation (
    input [1:0] in,
    output [1:0] out
);
    assign out = ~in;
endmodule

// 结果组合子模块
module Result_Combiner (
    input [1:0] xnor_result,
    output [3:0] full_result
);
    // 将XNOR结果与固定高位组合
    assign full_result = {2'b11, xnor_result};
endmodule