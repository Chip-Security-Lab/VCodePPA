//SystemVerilog
// 顶层模块
module xor3_1 (
    input wire A, B, C,
    output wire Y
);
    // 声明中间信号
    wire a_minterm, b_minterm, c_minterm, abc_minterm;
    
    // 实例化子模块
    minterm_generator minterm_inst (
        .A(A), .B(B), .C(C),
        .a_minterm(a_minterm),
        .b_minterm(b_minterm),
        .c_minterm(c_minterm),
        .abc_minterm(abc_minterm)
    );
    
    output_logic output_inst (
        .a_minterm(a_minterm),
        .b_minterm(b_minterm),
        .c_minterm(c_minterm),
        .abc_minterm(abc_minterm),
        .Y(Y)
    );
endmodule

// 子模块：优化后的最小项生成器
module minterm_generator (
    input wire A, B, C,
    output wire a_minterm, b_minterm, c_minterm, abc_minterm
);
    // 各变量取反信号生成
    wire not_A, not_B, not_C;
    not_gates not_generator (
        .A(A), .B(B), .C(C),
        .not_A(not_A), .not_B(not_B), .not_C(not_C)
    );
    
    // 最小项生成
    and_terms and_generator (
        .A(A), .B(B), .C(C),
        .not_A(not_A), .not_B(not_B), .not_C(not_C),
        .a_minterm(a_minterm),
        .b_minterm(b_minterm),
        .c_minterm(c_minterm),
        .abc_minterm(abc_minterm)
    );
endmodule

// 子模块：生成取反信号
module not_gates (
    input wire A, B, C,
    output wire not_A, not_B, not_C
);
    assign not_A = ~A;
    assign not_B = ~B;
    assign not_C = ~C;
endmodule

// 子模块：生成AND项
module and_terms (
    input wire A, B, C, not_A, not_B, not_C,
    output wire a_minterm, b_minterm, c_minterm, abc_minterm
);
    assign a_minterm = A & not_B & not_C;    // A·B'·C'
    assign b_minterm = not_A & B & not_C;    // A'·B·C'
    assign c_minterm = not_A & not_B & C;    // A'·B'·C
    assign abc_minterm = A & B & C;          // A·B·C
endmodule

// 子模块：输出逻辑，合并最小项
module output_logic (
    input wire a_minterm, b_minterm, c_minterm, abc_minterm,
    output wire Y
);
    // 使用参数化设计，便于后续修改或复用
    parameter OR_STAGE = 1;
    
    generate
        if (OR_STAGE == 1) begin: single_stage
            // 单级OR结构
            assign Y = a_minterm | b_minterm | c_minterm | abc_minterm;
        end
        else begin: two_stage
            // 两级OR结构，可能在某些工艺下有更好的PPA
            wire or_stage1_a, or_stage1_b;
            assign or_stage1_a = a_minterm | b_minterm;
            assign or_stage1_b = c_minterm | abc_minterm;
            assign Y = or_stage1_a | or_stage1_b;
        end
    endgenerate
endmodule