//SystemVerilog - IEEE 1364-2005
module d_ff_valid_ready (
    input wire clk,
    input wire rst_n,
    input wire preset_n,
    input wire d,
    input wire ready,  // 接收方准备接收数据的信号
    output reg q,
    output reg valid   // 数据有效信号
);
    // 内部状态寄存器
    reg data_reg;
    reg valid_pending;
    
    // 将复杂逻辑拆分为更多流水线阶段
    // 第一阶段: 输入采样和基本条件计算
    reg stage1_ready_signal;
    reg stage1_valid_signal;
    reg stage1_d;
    reg stage1_valid_pending;
    
    // 第二阶段: 条件组合计算
    reg stage2_ready_and_valid;
    reg stage2_not_ready_and_valid;
    reg stage2_valid_pending_or_not_valid;
    reg stage2_d;
    reg stage2_valid_pending;
    
    // 第三阶段: 进一步细分条件组合
    reg stage3_ready_and_valid;
    reg stage3_not_ready_and_valid;
    reg stage3_valid_pending_status;
    reg stage3_d;
    
    // 第一阶段：采样输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_ready_signal <= 1'b0;
            stage1_valid_signal <= 1'b0;
            stage1_d <= 1'b0;
            stage1_valid_pending <= 1'b0;
        end else begin
            stage1_ready_signal <= ready;
            stage1_valid_signal <= valid;
            stage1_d <= d;
            stage1_valid_pending <= valid_pending;
        end
    end
    
    // 第二阶段：基本条件组合计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_ready_and_valid <= 1'b0;
            stage2_not_ready_and_valid <= 1'b0;
            stage2_valid_pending_or_not_valid <= 1'b0;
            stage2_d <= 1'b0;
            stage2_valid_pending <= 1'b0;
        end else begin
            stage2_ready_and_valid <= stage1_ready_signal && stage1_valid_signal;
            stage2_not_ready_and_valid <= !stage1_ready_signal && stage1_valid_signal;
            stage2_valid_pending_or_not_valid <= stage1_valid_pending || !stage1_valid_signal;
            stage2_d <= stage1_d;
            stage2_valid_pending <= stage1_valid_pending;
        end
    end
    
    // 第三阶段：进一步细分条件逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_ready_and_valid <= 1'b0;
            stage3_not_ready_and_valid <= 1'b0;
            stage3_valid_pending_status <= 1'b0;
            stage3_d <= 1'b0;
        end else begin
            stage3_ready_and_valid <= stage2_ready_and_valid;
            stage3_not_ready_and_valid <= stage2_not_ready_and_valid;
            stage3_valid_pending_status <= stage2_valid_pending_or_not_valid;
            stage3_d <= stage2_d;
        end
    end
    
    // 第四阶段：数据寄存和valid信号控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 1'b0;
            valid <= 1'b0;
            valid_pending <= 1'b0;
        end else if (!preset_n) begin
            data_reg <= 1'b1;
            valid <= 1'b1;
            valid_pending <= 1'b0;
        end else begin
            // 使用流水线最后阶段的预计算条件
            if (stage3_ready_and_valid) begin
                data_reg <= stage3_d;
                valid <= 1'b1;
            end else if (stage3_not_ready_and_valid) begin
                valid_pending <= 1'b1;
            end else if (stage3_valid_pending_status) begin
                data_reg <= stage3_d;
                valid <= 1'b1;
                valid_pending <= 1'b0;
            end
        end
    end

    // 第五阶段：输出控制 - 使用流水线最后阶段寄存器的预计算条件
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 1'b0;  // Reset has priority
        else if (!preset_n)
            q <= 1'b1;  // Preset
        else if (stage3_ready_and_valid)
            q <= data_reg;  // 只在握手成功时更新输出
    end
endmodule