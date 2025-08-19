//SystemVerilog
module async_signal_recovery (
    input wire clk,              // 时钟信号
    input wire rst_n,            // 复位信号
    input wire [7:0] noisy_input,
    input wire signal_present,
    output reg [7:0] recovered_signal
);
    // 时钟缓冲区 - 降低时钟树扇出负载
    wire clk_buf1, clk_buf2, clk_buf3;
    
    // 时钟树缓冲结构
    assign clk_buf1 = clk;
    assign clk_buf2 = clk;
    assign clk_buf3 = clk;
    
    // 信号缓冲 - 减少rst_n的扇出负载
    wire rst_n_buf1, rst_n_buf2, rst_n_buf3;
    
    assign rst_n_buf1 = rst_n;
    assign rst_n_buf2 = rst_n;
    assign rst_n_buf3 = rst_n;
    
    // 第一级流水线 - 信号过滤阶段
    reg [7:0] filtered_signal_stage1;
    reg signal_present_stage1;
    
    // 第二级流水线 - 阈值检测阶段
    reg [7:0] filtered_signal_stage2;
    
    // 常数比较值缓冲 - 减少大扇出比较
    reg [7:0] threshold_value;
    
    // 阈值缓冲注册
    always @(posedge clk_buf1 or negedge rst_n_buf1) begin
        if (!rst_n_buf1) begin
            threshold_value <= 8'd128;
        end else begin
            threshold_value <= 8'd128; // 保持常数值
        end
    end
    
    // 数据流第一阶段 - 输入捕获与信号选择
    always @(posedge clk_buf1 or negedge rst_n_buf1) begin
        if (!rst_n_buf1) begin
            filtered_signal_stage1 <= 8'b0;
            signal_present_stage1 <= 1'b0;
        end else begin
            filtered_signal_stage1 <= noisy_input;
            signal_present_stage1 <= signal_present;
        end
    end
    
    // 数据流第二阶段 - 信号过滤处理
    always @(posedge clk_buf2 or negedge rst_n_buf2) begin
        if (!rst_n_buf2) begin
            filtered_signal_stage2 <= 8'b0;
        end else begin
            filtered_signal_stage2 <= signal_present_stage1 ? filtered_signal_stage1 : 8'b0;
        end
    end
    
    // 信号比较结果缓冲
    reg compare_result;
    always @(posedge clk_buf2 or negedge rst_n_buf2) begin
        if (!rst_n_buf2) begin
            compare_result <= 1'b0;
        end else begin
            compare_result <= (filtered_signal_stage2 > threshold_value);
        end
    end
    
    // 数据流第三阶段 - 阈值检测与信号恢复
    always @(posedge clk_buf3 or negedge rst_n_buf3) begin
        if (!rst_n_buf3) begin
            recovered_signal <= 8'b0;
        end else begin
            recovered_signal <= compare_result ? 8'hFF : 8'h00;
        end
    end
endmodule