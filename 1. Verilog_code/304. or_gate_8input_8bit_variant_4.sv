//SystemVerilog
module or_gate_8input_8bit (
    input wire [7:0] a,
    input wire [7:0] b,
    input wire [7:0] c,
    input wire [7:0] d,
    input wire [7:0] e,
    input wire [7:0] f,
    input wire [7:0] g,
    input wire [7:0] h,
    output wire [7:0] y
);
    // 中间信号
    wire [7:0] or_level1_out1, or_level1_out2, or_level1_out3, or_level1_out4;
    wire [7:0] or_level2_out1, or_level2_out2;
    
    // 第一级或运算
    or_gate_2input_8bit or_level1_1 (.a(a), .b(b), .y(or_level1_out1));
    or_gate_2input_8bit or_level1_2 (.a(c), .b(d), .y(or_level1_out2));
    or_gate_2input_8bit or_level1_3 (.a(e), .b(f), .y(or_level1_out3));
    or_gate_2input_8bit or_level1_4 (.a(g), .b(h), .y(or_level1_out4));
    
    // 第二级或运算
    or_gate_2input_8bit or_level2_1 (.a(or_level1_out1), .b(or_level1_out2), .y(or_level2_out1));
    or_gate_2input_8bit or_level2_2 (.a(or_level1_out3), .b(or_level1_out4), .y(or_level2_out2));
    
    // 最终或运算
    or_gate_2input_8bit or_final (.a(or_level2_out1), .b(or_level2_out2), .y(y));
    
endmodule

// 基本2输入8位或门模块
module or_gate_2input_8bit (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] y
);
    // 位并行或运算
    assign y = a | b;
endmodule