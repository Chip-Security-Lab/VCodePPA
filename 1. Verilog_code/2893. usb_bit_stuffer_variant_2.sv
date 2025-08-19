//SystemVerilog
module usb_bit_stuffer(
    input  wire clk_i,
    input  wire rst_i,
    input  wire bit_i,
    input  wire valid_i,
    output reg  bit_o,
    output reg  valid_o,
    output reg  stuffed_o
);
    // 常量定义
    localparam MAX_ONES = 6;
    localparam STUFF_THRESHOLD = MAX_ONES - 1;
    
    // 流水线阶段1：输入缓冲和同步
    reg bit_stage1, valid_stage1;
    
    // 流水线阶段2：计数和逻辑处理
    reg bit_stage2, valid_stage2;
    reg [2:0] ones_count_stage2;
    reg is_one_stage2;
    reg count_at_threshold_stage2;
    
    // 流水线阶段3：计数更新和决策
    reg bit_stage3, valid_stage3;
    reg [2:0] ones_count_stage3;
    reg should_stuff_stage3;
    
    // 流水线阶段4：输出准备
    reg bit_stage4, valid_stage4;
    reg stuffed_stage4;
    
    // 提前计算阶段2使用的条件
    wire count_reset = !bit_stage1;
    wire count_restart = ones_count_stage2 == MAX_ONES;
    wire count_increment = bit_stage1 && (ones_count_stage2 < MAX_ONES);
    
    // 阶段1：输入缓冲 - 分离寄存器逻辑以减少关键路径
    always @(posedge clk_i) begin
        if (rst_i) begin
            bit_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            bit_stage1 <= bit_i;
            valid_stage1 <= valid_i;
        end
    end
    
    // 阶段2：计数和位检测 - 预计算下一个周期可能使用的值
    always @(posedge clk_i) begin
        if (rst_i) begin
            bit_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            ones_count_stage2 <= 3'd0;
            is_one_stage2 <= 1'b0;
            count_at_threshold_stage2 <= 1'b0;
        end else begin
            bit_stage2 <= bit_stage1;
            valid_stage2 <= valid_stage1;
            is_one_stage2 <= bit_stage1;
            
            // 预计算阈值检查，分解条件判断
            count_at_threshold_stage2 <= (ones_count_stage2 == STUFF_THRESHOLD);
            
            if (valid_stage1) begin
                if (count_reset) begin
                    ones_count_stage2 <= 3'd0;
                end else if (count_restart) begin
                    ones_count_stage2 <= 3'd1; // 填充0后又来了个1
                end else if (count_increment) begin
                    ones_count_stage2 <= ones_count_stage2 + 1'b1;
                end
            end
        end
    end
    
    // 阶段3：决策逻辑 - 简化条件检查，使用预计算的值
    always @(posedge clk_i) begin
        if (rst_i) begin
            bit_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
            ones_count_stage3 <= 3'd0;
            should_stuff_stage3 <= 1'b0;
        end else begin
            bit_stage3 <= bit_stage2;
            valid_stage3 <= valid_stage2;
            ones_count_stage3 <= ones_count_stage2;
            
            // 使用预计算的条件简化决策逻辑
            should_stuff_stage3 <= valid_stage2 && count_at_threshold_stage2 && is_one_stage2;
        end
    end
    
    // 阶段4：输出准备 - 并行化stuffed位和输出位的计算
    always @(posedge clk_i) begin
        if (rst_i) begin
            bit_stage4 <= 1'b0;
            valid_stage4 <= 1'b0;
            stuffed_stage4 <= 1'b0;
        end else begin
            valid_stage4 <= valid_stage3;
            bit_stage4 <= should_stuff_stage3 ? 1'b0 : bit_stage3;
            stuffed_stage4 <= should_stuff_stage3;
        end
    end
    
    // 最终输出阶段 - 保持简单直接的寄存器传输
    always @(posedge clk_i) begin
        if (rst_i) begin
            bit_o <= 1'b0;
            valid_o <= 1'b0;
            stuffed_o <= 1'b0;
        end else begin
            bit_o <= bit_stage4;
            valid_o <= valid_stage4;
            stuffed_o <= stuffed_stage4;
        end
    end
    
endmodule