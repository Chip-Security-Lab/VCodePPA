//SystemVerilog
module PipelinedOR(
    input clk,
    input [15:0] stage_a, stage_b,
    output reg [15:0] out
);
    // 直接在第一级执行OR操作，减少输入到第一级寄存器的延迟
    wire [3:0] or_result_l = stage_a[3:0] | stage_b[3:0];
    wire [3:0] or_result_h = stage_a[7:4] | stage_b[7:4];
    wire [3:0] or_result_hh = stage_a[11:8] | stage_b[11:8];
    wire [3:0] or_result_hhh = stage_a[15:12] | stage_b[15:12];
    
    // 第一级流水线寄存器，直接存储OR运算结果
    reg [3:0] stage1_l, stage1_h, stage1_hh, stage1_hhh;
    
    // 第二级流水线寄存器
    reg [7:0] stage2_l, stage2_h;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    
    // 第一级流水线：直接存储组合逻辑计算结果
    always @(posedge clk) begin
        stage1_l <= or_result_l;
        stage1_h <= or_result_h;
        stage1_hh <= or_result_hh;
        stage1_hhh <= or_result_hhh;
        
        valid_stage1 <= 1'b1; // 输入始终有效
    end
    
    // 第二级流水线：合并为两个8位结果
    always @(posedge clk) begin
        if (valid_stage1) begin
            stage2_l <= {stage1_h, stage1_l};
            stage2_h <= {stage1_hhh, stage1_hh};
            valid_stage2 <= valid_stage1;
        end else begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // 最终级流水线：合并为完整的16位输出
    always @(posedge clk) begin
        if (valid_stage2) begin
            out <= {stage2_h, stage2_l};
        end
    end
endmodule