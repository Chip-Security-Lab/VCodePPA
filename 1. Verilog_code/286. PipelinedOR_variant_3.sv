//SystemVerilog
module PipelinedOR(
    input clk,
    input [15:0] stage_a, stage_b,
    output [15:0] out
);
    // 内部连线
    wire [15:0] logic_result_part1;
    wire [15:0] logic_result_part2;
    wire [15:0] pipeline_result;
    
    // 逻辑运算子模块 - 分为两个部分以减少关键路径
    LogicOperation logic_op_inst (
        .operand_a(stage_a),
        .operand_b(stage_b),
        .result_part1(logic_result_part1),
        .result_part2(logic_result_part2)
    );
    
    // 中间流水线寄存器
    PipelineRegister pipeline_reg_inst (
        .clk(clk),
        .part1_in(logic_result_part1),
        .part2_in(logic_result_part2),
        .result_out(pipeline_result)
    );
    
    // 输出寄存器子模块
    RegisterStage reg_stage_inst (
        .clk(clk),
        .data_in(pipeline_result),
        .data_out(out)
    );
    
endmodule

module LogicOperation #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] operand_a,
    input [WIDTH-1:0] operand_b,
    output [WIDTH-1:0] result_part1,
    output [WIDTH-1:0] result_part2
);
    // 将OR操作分割为两个部分以减少关键路径
    // 低位部分
    assign result_part1 = operand_a[7:0] | operand_b[7:0];
    // 高位部分
    assign result_part2 = operand_a[15:8] | operand_b[15:8];
endmodule

module PipelineRegister #(
    parameter WIDTH = 16
)(
    input clk,
    input [7:0] part1_in,
    input [7:0] part2_in,
    output [WIDTH-1:0] result_out
);
    // 流水线中间寄存器
    reg [7:0] part1_reg;
    reg [7:0] part2_reg;
    
    always @(posedge clk) begin
        part1_reg <= part1_in;
        part2_reg <= part2_in;
    end
    
    // 合并两部分结果
    assign result_out = {part2_reg, part1_reg};
endmodule

module RegisterStage #(
    parameter WIDTH = 16
)(
    input clk,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    // 时序逻辑，用于流水线寄存
    always @(posedge clk) begin
        data_out <= data_in;
    end
endmodule