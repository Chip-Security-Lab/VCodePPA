//SystemVerilog
module async_threshold_filter #(
    parameter DATA_W = 8
)(
    input wire clk,                  // 时钟信号
    input wire rst_n,                // 复位信号
    input wire [DATA_W-1:0] in_signal,
    input wire [DATA_W-1:0] high_thresh,
    input wire [DATA_W-1:0] low_thresh,
    input wire current_state,
    output reg next_state
);
    // 内部信号定义 - 分解比较逻辑
    wire is_below_low;
    wire is_above_high;
    
    // 第一级流水线 - 比较逻辑
    assign is_below_low = (in_signal < low_thresh);
    assign is_above_high = (in_signal > high_thresh);
    
    // 第二级流水线 - 状态决策逻辑
    reg is_below_low_reg;
    reg is_above_high_reg;
    reg current_state_reg;
    
    // 扇出缓冲 - 为高扇出信号添加缓冲寄存器
    // 将current_state信号分散到多个缓冲寄存器
    reg current_state_buf1, current_state_buf2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            is_below_low_reg <= 1'b0;
            is_above_high_reg <= 1'b0;
            current_state_reg <= 1'b0;
            current_state_buf1 <= 1'b0;
            current_state_buf2 <= 1'b0;
        end else begin
            is_below_low_reg <= is_below_low;
            is_above_high_reg <= is_above_high;
            current_state_reg <= current_state;
            current_state_buf1 <= current_state;
            current_state_buf2 <= current_state;
        end
    end
    
    // 中间控制信号 - 减少逻辑层级和负载
    reg next_state_for_high;
    reg next_state_for_low;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_state_for_high <= 1'b0;
            next_state_for_low <= 1'b0;
        end else begin
            next_state_for_high <= is_above_high_reg ? 1'b1 : 1'b0;
            next_state_for_low <= is_below_low_reg ? 1'b0 : 1'b1;
        end
    end
    
    // 第三级流水线 - 输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_state <= 1'b0;
        end else begin
            next_state <= current_state_buf1 ? next_state_for_low : next_state_for_high;
        end
    end
endmodule