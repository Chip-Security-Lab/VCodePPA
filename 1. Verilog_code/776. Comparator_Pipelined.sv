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
    // 流水线寄存器组
    reg [PIPELINE_STAGES-1:0] stage_eq;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage_eq <= {PIPELINE_STAGES{1'b0}};
        end else begin
            stage_eq <= {stage_eq[PIPELINE_STAGES-2:0], (operand_a == operand_b)};
        end
    end
    
    assign result = stage_eq[PIPELINE_STAGES-1];
endmodule