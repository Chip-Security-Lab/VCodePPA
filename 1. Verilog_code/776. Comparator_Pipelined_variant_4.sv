//SystemVerilog
module Comparator_Pipelined #(
    parameter WIDTH = 64,         // 支持大位宽比较
    parameter PIPELINE_STAGES = 3 // 可配置流水级数
)(
    input               clk,
    input               rst_n,
    input  [WIDTH-1:0]  operand_a,
    input  [WIDTH-1:0]  operand_b,
    output              result
);
    // 定义内部信号
    wire [WIDTH-1:0] b_complement;
    wire cin;
    wire [WIDTH:0] subtraction_result;
    wire is_equal;
    
    // 条件反相减法器实现
    // 当进行A-B操作时，我们对B取反并加1（二进制补码）
    assign cin = 1'b1; // 减法运算的进位输入为1
    assign b_complement = ~operand_b; // 对B取反
    
    // 执行减法A-B，使用条件反相减法器算法
    // 如果A==B，则结果为0
    assign subtraction_result = operand_a + b_complement + cin;
    assign is_equal = (subtraction_result[WIDTH-1:0] == {WIDTH{1'b0}});
    
    // 流水线寄存器组
    reg [PIPELINE_STAGES-1:0] stage_eq;

    always @(posedge clk or negedge rst_n) begin
        stage_eq <= (!rst_n) ? {PIPELINE_STAGES{1'b0}} : {stage_eq[PIPELINE_STAGES-2:0], is_equal};
    end
    
    assign result = stage_eq[PIPELINE_STAGES-1];
endmodule