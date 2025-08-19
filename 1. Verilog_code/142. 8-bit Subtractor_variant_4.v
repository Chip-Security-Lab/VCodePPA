// 补码计算子模块
module twos_complement (
    input wire [7:0] operand,
    output wire [7:0] complement
);
    assign complement = ~operand + 1'b1;
endmodule

// 加法运算子模块
module adder_8bit (
    input wire [7:0] operand_a,
    input wire [7:0] operand_b,
    output wire [7:0] sum
);
    assign sum = operand_a + operand_b;
endmodule

// 顶层减法器模块
module subtractor_8bit (
    input wire [7:0] operand_a,
    input wire [7:0] operand_b,
    output wire [7:0] result
);

wire [7:0] operand_b_comp;

// 实例化补码计算模块
twos_complement comp_inst (
    .operand(operand_b),
    .complement(operand_b_comp)
);

// 实例化加法模块
adder_8bit add_inst (
    .operand_a(operand_a),
    .operand_b(operand_b_comp),
    .sum(result)
);

endmodule