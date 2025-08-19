//SystemVerilog
// 顶层模块
module nand_xor_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);
    // 内部连线
    wire nand_out;        // NAND门输出
    wire xor_result;      // XOR操作结果
    
    // 实例化NAND子模块
    nand_logic nand_inst (
        .in_a(A),
        .in_b(B),
        .out(nand_out)
    );
    
    // 实例化XOR子模块
    xor_logic xor_inst (
        .in_a(nand_out),
        .in_b(C),
        .out(xor_result)
    );
    
    // 实例化表达式优化子模块
    expression_optimizer opt_inst (
        .A(A),
        .B(B),
        .C(C),
        .Y(Y)
    );
endmodule

// NAND逻辑子模块
module nand_logic #(
    parameter INVERTED_OUTPUT = 1  // 1表示输出为NAND，0表示输出为AND
) (
    input wire in_a,
    input wire in_b,
    output wire out
);
    generate
        if (INVERTED_OUTPUT) begin : gen_nand
            assign out = ~(in_a & in_b);
        end else begin : gen_and
            assign out = in_a & in_b;
        end
    endgenerate
endmodule

// XOR逻辑子模块
module xor_logic (
    input wire in_a,
    input wire in_b,
    output wire out
);
    // XOR实现: X ^ Y = (X & ~Y) | (~X & Y)
    wire a_and_not_b;
    wire not_a_and_b;
    
    assign a_and_not_b = in_a & ~in_b;
    assign not_a_and_b = ~in_a & in_b;
    assign out = a_and_not_b | not_a_and_b;
endmodule

// 表达式优化子模块 - 实现了优化后的布尔表达式
module expression_optimizer (
    input wire A, B, C,
    output wire Y
);
    // 对表达式 (~A | ~B) ^ C 进行优化
    // 优化为: (~A & ~C) | (~B & ~C) | (A & B & C)
    
    wire term1, term2, term3;
    
    assign term1 = ~A & ~C;
    assign term2 = ~B & ~C;
    assign term3 = A & B & C;
    
    assign Y = term1 | term2 | term3;
endmodule