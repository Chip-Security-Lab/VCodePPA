//SystemVerilog
// SystemVerilog
module toggle_ff_count_enable (
    input wire clk,
    input wire rst_n,
    input wire count_en,
    input wire data_valid_in,
    output wire data_ready_out,
    output reg [3:0] q,
    output reg data_valid_out
);
    // 后向重定时优化：将寄存器从输出端向前移动穿过组合逻辑
    
    // 数据路径寄存器
    reg [3:0] q_internal;       // 内部计数器状态
    
    // 流水线控制信号和重定时寄存器
    reg data_valid_stage1;      // 第一级有效信号
    reg data_valid_stage2;      // 第二级有效信号
    reg data_valid_pre_out;     // 预输出有效信号
    
    // 输入就绪信号 - 简化设计中始终就绪
    assign data_ready_out = 1'b1;
    
    // 内部计数器更新逻辑 - 优化前置组合逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_internal <= 4'b0000;
        end
        else begin
            if (data_valid_in && data_ready_out && count_en) begin
                q_internal <= q_internal + 1'b1;
            end
        end
    end
    
    // 第一级流水线控制 - 重定时优化
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_valid_stage1 <= 1'b0;
        end
        else begin
            if (data_valid_in && data_ready_out) begin
                data_valid_stage1 <= 1'b1;
            end
            else if (data_valid_stage1 && (!data_valid_stage2 || data_valid_pre_out)) begin
                data_valid_stage1 <= 1'b0;
            end
        end
    end
    
    // 第二级流水线控制 - 重定时优化
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_valid_stage2 <= 1'b0;
        end
        else begin
            if (data_valid_stage1 && (!data_valid_stage2 || data_valid_pre_out)) begin
                data_valid_stage2 <= 1'b1;
            end
            else if (data_valid_stage2 && data_valid_pre_out) begin
                data_valid_stage2 <= 1'b0;
            end
        end
    end
    
    // 预输出有效信号控制 - 后向重定时
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_valid_pre_out <= 1'b0;
        end
        else begin
            if (data_valid_stage2) begin
                data_valid_pre_out <= 1'b1;
            end
            else begin
                data_valid_pre_out <= 1'b0;
            end
        end
    end
    
    // 输出寄存器 - 优化后移多一级寄存器减少输出路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 4'b0000;
            data_valid_out <= 1'b0;
        end
        else begin
            if (data_valid_pre_out) begin
                q <= count_en ? q_internal : q;
                data_valid_out <= 1'b1;
            end
            else begin
                data_valid_out <= 1'b0;
            end
        end
    end
endmodule