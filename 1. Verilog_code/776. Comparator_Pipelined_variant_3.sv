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
    // 组合逻辑输出线网声明
    wire comparison_result;
    
    // 流水线寄存器组
    reg [PIPELINE_STAGES-1:0] stage_eq;
    
    // 组合逻辑部分 - 比较操作
    Comparator_Comb #(
        .WIDTH(WIDTH)
    ) comparator_inst (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .equal(comparison_result)
    );
    
    // 时序逻辑部分 - 流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage_eq <= {PIPELINE_STAGES{1'b0}};
        end else begin
            stage_eq <= {stage_eq[PIPELINE_STAGES-2:0], comparison_result};
        end
    end
    
    // 输出赋值
    assign result = stage_eq[PIPELINE_STAGES-1];
endmodule

// 纯组合逻辑模块
module Comparator_Comb #(
    parameter WIDTH = 64
)(
    input  [WIDTH-1:0] operand_a,
    input  [WIDTH-1:0] operand_b,
    output             equal
);
    // 组合逻辑实现比较操作
    assign equal = (operand_a == operand_b);
endmodule