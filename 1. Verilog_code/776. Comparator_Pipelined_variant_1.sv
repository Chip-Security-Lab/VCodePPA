//SystemVerilog
// 分段比较子模块
module SegmentComparator #(
    parameter WIDTH = 64,
    parameter SEG_SIZE = 21
)(
    input  [SEG_SIZE-1:0] operand_a,
    input  [SEG_SIZE-1:0] operand_b,
    output                segment_eq
);
    assign segment_eq = (operand_a == operand_b);
endmodule

// 流水线控制子模块
module PipelineControl #(
    parameter PIPELINE_STAGES = 3
)(
    input               clk,
    input               rst_n,
    input  [PIPELINE_STAGES-1:0] segment_eq,
    output [PIPELINE_STAGES-1:0] stage_eq,
    output [PIPELINE_STAGES-2:0] accum_eq
);
    reg [PIPELINE_STAGES-1:0] stage_eq_reg;
    reg [PIPELINE_STAGES-2:0] accum_eq_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage_eq_reg <= {PIPELINE_STAGES{1'b0}};
            accum_eq_reg <= {(PIPELINE_STAGES-1){1'b1}};
        end else begin
            stage_eq_reg[0] <= segment_eq[0];
            
            for (int j = 1; j < PIPELINE_STAGES; j = j + 1) begin
                accum_eq_reg[j-1] <= (j == 1) ? stage_eq_reg[0] : accum_eq_reg[j-2] & stage_eq_reg[j-1];
                stage_eq_reg[j] <= segment_eq[j] & ((j == 1) ? stage_eq_reg[0] : accum_eq_reg[j-2]);
            end
        end
    end
    
    assign stage_eq = stage_eq_reg;
    assign accum_eq = accum_eq_reg;
endmodule

// 顶层比较器模块
module Comparator_Pipelined #(
    parameter WIDTH = 64,
    parameter PIPELINE_STAGES = 3,
    parameter SEG_SIZE = WIDTH/PIPELINE_STAGES
)(
    input               clk,
    input               rst_n,
    input  [WIDTH-1:0]  operand_a,
    input  [WIDTH-1:0]  operand_b,
    output              result
);
    wire [PIPELINE_STAGES-1:0] segment_eq;
    wire [PIPELINE_STAGES-1:0] stage_eq;
    wire [PIPELINE_STAGES-2:0] accum_eq;
    
    genvar i;
    generate
        for (i = 0; i < PIPELINE_STAGES-1; i = i + 1) begin: comp_segments
            SegmentComparator #(
                .WIDTH(WIDTH),
                .SEG_SIZE(SEG_SIZE)
            ) segment_comp (
                .operand_a(operand_a[(i+1)*SEG_SIZE-1:i*SEG_SIZE]),
                .operand_b(operand_b[(i+1)*SEG_SIZE-1:i*SEG_SIZE]),
                .segment_eq(segment_eq[i])
            );
        end
        
        SegmentComparator #(
            .WIDTH(WIDTH),
            .SEG_SIZE(WIDTH-(PIPELINE_STAGES-1)*SEG_SIZE)
        ) last_segment_comp (
            .operand_a(operand_a[WIDTH-1:(PIPELINE_STAGES-1)*SEG_SIZE]),
            .operand_b(operand_b[WIDTH-1:(PIPELINE_STAGES-1)*SEG_SIZE]),
            .segment_eq(segment_eq[PIPELINE_STAGES-1])
        );
    endgenerate
    
    PipelineControl #(
        .PIPELINE_STAGES(PIPELINE_STAGES)
    ) pipeline_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .segment_eq(segment_eq),
        .stage_eq(stage_eq),
        .accum_eq(accum_eq)
    );
    
    assign result = stage_eq[PIPELINE_STAGES-1];
endmodule