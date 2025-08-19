//SystemVerilog
module or_gate_3input_4bit_always (
    input wire [3:0] a,
    input wire [3:0] b,
    input wire [3:0] c,
    output wire [3:0] y
);
    wire [3:0] ab_or;
    
    // 第一级OR操作子模块
    or_gate_2input_4bit or_ab_inst (
        .a(a),
        .b(b),
        .y(ab_or)
    );
    
    // 第二级OR操作子模块
    or_gate_2input_4bit or_abc_inst (
        .a(ab_or),
        .b(c),
        .y(y)
    );
endmodule

module or_gate_2input_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire [3:0] y
);
    // 使用assign语句替代always块，减少资源使用
    assign y = a | b;
endmodule