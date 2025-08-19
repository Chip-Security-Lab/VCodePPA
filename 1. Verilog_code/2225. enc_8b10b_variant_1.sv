//SystemVerilog
//IEEE 1364-2005 Verilog
module enc_8b10b #(parameter IMPLEMENT_TABLES = 1)
(
    input wire clk, reset_n, enable,
    input wire k_in,        // Control signal indicator
    input wire [7:0] data_in,
    input wire [9:0] encoded_in,
    output reg [9:0] encoded_out,
    output reg [7:0] data_out,
    output reg k_out,       // Decoded control indicator
    output reg disparity_err, code_err,
    // 新增流水线控制信号
    input wire valid_in,
    output reg valid_out,
    input wire ready_in,
    output wire ready_out
);
    // 流水线阶段寄存器
    reg disp_state_stage1, disp_state_stage2;   // 流水线阶段的视差状态
    reg [5:0] lut_5b6b_idx_stage1;              // 阶段1保存的5b6b索引
    reg [3:0] lut_3b4b_idx_stage1;              // 阶段1保存的3b4b索引
    reg [5:0] encoded_5b_stage2;                // 阶段2保存的5b编码结果
    reg k_in_stage1, k_in_stage2;               // 各阶段的控制信号
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2;             // 各阶段的有效信号
    wire stall_stage1;                          // 流水线阻塞信号
    
    // 流水线反压控制逻辑
    assign stall_stage1 = valid_stage2 && !ready_in;
    assign ready_out = !stall_stage1;
    
    // 第一级流水线：计算查找表索引
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            lut_5b6b_idx_stage1 <= 6'b0;
            lut_3b4b_idx_stage1 <= 4'b0;
            k_in_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            disp_state_stage1 <= 1'b0;
        end else if (enable && ready_out) begin
            if (valid_in) begin
                // 预计算索引并保存到第一级流水线
                lut_5b6b_idx_stage1 <= {k_in, data_in[4:0]};
                lut_3b4b_idx_stage1 <= data_in[7:5];
                k_in_stage1 <= k_in;
                disp_state_stage1 <= disp_state_stage2; // 使用当前视差状态
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // 第二级流水线：执行编码计算
    reg [3:0] encoded_3b_comb;
    reg [5:0] encoded_5b_comb;
    
    always @(*) begin
        if (IMPLEMENT_TABLES) begin
            encoded_5b_comb = compute_5b6b_encoding(lut_5b6b_idx_stage1, disp_state_stage1);
            encoded_3b_comb = compute_3b4b_encoding(lut_3b4b_idx_stage1, disp_state_stage1, encoded_5b_comb);
        end else begin
            encoded_5b_comb = 6'b0;
            encoded_3b_comb = 4'b0;
        end
    end
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            encoded_5b_stage2 <= 6'b0;
            valid_stage2 <= 1'b0;
            k_in_stage2 <= 1'b0;
            disp_state_stage2 <= 1'b0;
        end else if (enable && !stall_stage1) begin
            if (valid_stage1) begin
                // 保存编码结果到第二级流水线
                encoded_5b_stage2 <= encoded_5b_comb;
                encoded_3b_stage2 <= encoded_3b_comb;
                k_in_stage2 <= k_in_stage1;
                valid_stage2 <= 1'b1;
                
                // 更新视差状态
                disp_state_stage2 <= calculate_new_disparity({encoded_3b_comb, encoded_5b_comb}, disp_state_stage1);
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // 第三级流水线：最终输出
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            encoded_out <= 10'b0;
            valid_out <= 1'b0;
        end else if (enable && ready_in) begin
            if (valid_stage2) begin
                // 最终输出结果
                encoded_out <= {encoded_3b_stage2, encoded_5b_stage2};
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end else if (!enable) begin
            valid_out <= 1'b0;
        end
    end
    
    // 解码逻辑管道
    reg [9:0] encoded_in_stage1;
    reg encoded_valid_stage1;
    reg [7:0] data_out_comb;
    reg k_out_comb;
    reg disparity_err_comb, code_err_comb;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            encoded_in_stage1 <= 10'b0;
            encoded_valid_stage1 <= 1'b0;
        end else if (enable) begin
            encoded_in_stage1 <= encoded_in;
            encoded_valid_stage1 <= valid_in;
        end
    end
    
    // 解码组合逻辑
    always @(*) begin
        // 这里处理解码逻辑（占位符）
        data_out_comb = 8'b0;
        k_out_comb = 1'b0;
        disparity_err_comb = 1'b0;
        code_err_comb = 1'b0;
    end
    
    // 解码输出阶段
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_out <= 8'b0;
            k_out <= 1'b0;
            disparity_err <= 1'b0;
            code_err <= 1'b0;
        end else if (enable) begin
            if (encoded_valid_stage1) begin
                data_out <= data_out_comb;
                k_out <= k_out_comb;
                disparity_err <= disparity_err_comb;
                code_err <= code_err_comb;
            end
        end
    end
    
    // 编码辅助函数
    function [5:0] compute_5b6b_encoding;
        input [5:0] idx;
        input disp;
        begin
            // 实际编码表逻辑的占位符
            compute_5b6b_encoding = idx; // 简化示例
        end
    endfunction
    
    // 3b4b编码辅助函数
    function [3:0] compute_3b4b_encoding;
        input [3:0] idx;
        input disp;
        input [5:0] encoded_5b_val;
        begin
            // 实际编码表逻辑的占位符
            compute_3b4b_encoding = idx; // 简化示例
        end
    endfunction
    
    // 计算新的运行视差辅助函数
    function calculate_new_disparity;
        input [9:0] encoded;
        input current_disp;
        begin
            // 根据编码位计算新的视差
            // 计算1和0的数量以确定是正视差还是负视差
            // 实际实现的占位符
            calculate_new_disparity = current_disp; // 简化示例
        end
    endfunction
    
    // 编码阶段2寄存器
    reg [3:0] encoded_3b_stage2;
endmodule