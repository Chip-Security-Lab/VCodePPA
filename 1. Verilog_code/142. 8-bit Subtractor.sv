module subtractor_8bit (
    input wire [7:0] operand_a,  // 被减数
    input wire [7:0] operand_b,  // 减数
    output wire [7:0] result    // 差
);

assign result = operand_a - operand_b;  // 组合逻辑直接运算

endmodule