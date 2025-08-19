//SystemVerilog
module peak_detection_recovery (
    input wire clk,
    input wire rst_n,
    input wire [9:0] signal_in,
    output reg [9:0] peak_value,
    output reg peak_detected
);
    // 第一级流水线寄存器 - 存储输入信号历史
    reg [9:0] stage1_value;
    reg [9:0] stage2_value;
    reg [9:0] stage3_value;
    reg [9:0] stage4_value;
    reg [9:0] stage5_value;
    
    // 第二级流水线寄存器 - 比较操作的中间结果1
    reg stage2_greater_than_stage1_part1;
    reg stage2_greater_than_stage3_part1;
    
    // 第三级流水线寄存器 - 比较操作的中间结果2
    reg stage2_greater_than_stage1_part2;
    reg stage2_greater_than_stage3_part2;
    
    // 第四级流水线寄存器 - 用于比较计算最终结果
    reg stage2_greater_than_stage1;
    reg stage2_greater_than_stage3;
    
    // 第五级流水线寄存器 - 峰值条件计算中间结果
    reg peak_condition_stage5_part1;
    
    // 第六级流水线寄存器 - 用于暂存峰值候选
    reg [9:0] peak_candidate_stage6;
    reg peak_condition_stage6;
    
    // 第七级流水线寄存器 - 用于输出准备
    reg [9:0] peak_candidate_stage7;
    reg peak_condition_stage7;
    
    // 第一级流水线 - 更新历史值 (1/2)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_value <= 10'h0;
            stage2_value <= 10'h0;
            stage3_value <= 10'h0;
        end else begin
            stage1_value <= signal_in;
            stage2_value <= stage1_value;
            stage3_value <= stage2_value;
        end
    end
    
    // 第一级流水线 - 更新历史值 (2/2)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage4_value <= 10'h0;
            stage5_value <= 10'h0;
        end else begin
            stage4_value <= stage3_value;
            stage5_value <= stage4_value;
        end
    end
    
    // 第二级流水线 - 执行比较操作第一阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_greater_than_stage1_part1 <= 1'b0;
            stage2_greater_than_stage3_part1 <= 1'b0;
        end else begin
            stage2_greater_than_stage1_part1 <= (stage3_value > stage2_value);
            stage2_greater_than_stage3_part1 <= (stage3_value > stage4_value);
        end
    end
    
    // 第三级流水线 - 执行比较操作第二阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_greater_than_stage1_part2 <= 1'b0;
            stage2_greater_than_stage3_part2 <= 1'b0;
        end else begin
            stage2_greater_than_stage1_part2 <= stage2_greater_than_stage1_part1;
            stage2_greater_than_stage3_part2 <= stage2_greater_than_stage3_part1;
        end
    end
    
    // 第四级流水线 - 比较操作最终结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_greater_than_stage1 <= 1'b0;
            stage2_greater_than_stage3 <= 1'b0;
        end else begin
            stage2_greater_than_stage1 <= stage2_greater_than_stage1_part2;
            stage2_greater_than_stage3 <= stage2_greater_than_stage3_part2;
        end
    end
    
    // 第五级流水线 - 计算峰值条件第一阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            peak_condition_stage5_part1 <= 1'b0;
        end else begin
            peak_condition_stage5_part1 <= stage2_greater_than_stage1 && stage2_greater_than_stage3;
        end
    end
    
    // 第六级流水线 - 计算峰值条件和候选值
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            peak_condition_stage6 <= 1'b0;
            peak_candidate_stage6 <= 10'h0;
        end else begin
            peak_condition_stage6 <= peak_condition_stage5_part1;
            peak_candidate_stage6 <= stage5_value;
        end
    end
    
    // 第七级流水线 - 准备输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            peak_condition_stage7 <= 1'b0;
            peak_candidate_stage7 <= 10'h0;
        end else begin
            peak_condition_stage7 <= peak_condition_stage6;
            peak_candidate_stage7 <= peak_candidate_stage6;
        end
    end
    
    // 第八级流水线 - 输出峰值检测和峰值结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            peak_detected <= 1'b0;
            peak_value <= 10'h0;
        end else begin
            peak_detected <= peak_condition_stage7;
            if (peak_condition_stage7) begin
                peak_value <= peak_candidate_stage7;
            end
        end
    end
endmodule