//SystemVerilog
module Demux_CDC #(parameter DW=8) (
    input clk_a, clk_b,
    input [DW-1:0] data_a,
    input sel_a,
    input valid_in,    // 流水线控制信号：输入数据有效
    output reg [DW-1:0] data_b0,
    output reg [DW-1:0] data_b1,
    output reg valid_out  // 流水线控制信号：输出数据有效
);
    // 第一级流水线：在时钟域A中寄存输入数据和选择信号
    reg [DW-1:0] data_a_stage1;
    reg sel_a_stage1;
    reg valid_stage1;
    
    always @(posedge clk_a) begin
        data_a_stage1 <= data_a;
        sel_a_stage1 <= sel_a;
        valid_stage1 <= valid_in;
    end
    
    // 第二级流水线：在时钟域A中应用选择逻辑，创建两条路径
    reg [DW-1:0] path0_a_stage2, path1_a_stage2;
    reg valid_stage2;
    
    always @(posedge clk_a) begin
        path0_a_stage2 <= sel_a_stage1 ? data_a_stage1 : {DW{1'b0}};
        path1_a_stage2 <= !sel_a_stage1 ? data_a_stage1 : {DW{1'b0}};
        valid_stage2 <= valid_stage1;
    end
    
    // 第三级流水线：在时钟域A中进一步细化数据处理（可以添加额外处理逻辑）
    reg [DW-1:0] path0_a_stage3, path1_a_stage3;
    reg valid_stage3;
    
    always @(posedge clk_a) begin
        path0_a_stage3 <= path0_a_stage2;
        path1_a_stage3 <= path1_a_stage2;
        valid_stage3 <= valid_stage2;
    end
    
    // 时钟域转换暂存器：捕获时钟域A的最终数据
    reg [DW-1:0] path0_a_final, path1_a_final;
    reg valid_a_final;
    
    always @(posedge clk_a) begin
        path0_a_final <= path0_a_stage3;
        path1_a_final <= path1_a_stage3;
        valid_a_final <= valid_stage3;
    end
    
    // 时钟域B第一级：捕获来自时钟域A的数据
    reg [DW-1:0] path0_b_stage1, path1_b_stage1;
    reg valid_b_stage1;
    
    always @(posedge clk_b) begin
        path0_b_stage1 <= path0_a_final;
        path1_b_stage1 <= path1_a_final;
        valid_b_stage1 <= valid_a_final;
    end
    
    // 时钟域B第二级：额外的处理步骤，可以根据需要添加处理逻辑
    reg [DW-1:0] path0_b_stage2, path1_b_stage2;
    reg valid_b_stage2;
    
    always @(posedge clk_b) begin
        path0_b_stage2 <= path0_b_stage1;
        path1_b_stage2 <= path1_b_stage1;
        valid_b_stage2 <= valid_b_stage1;
    end
    
    // 最终输出阶段
    always @(posedge clk_b) begin
        data_b0 <= path0_b_stage2;
        data_b1 <= path1_b_stage2;
        valid_out <= valid_b_stage2;
    end
endmodule