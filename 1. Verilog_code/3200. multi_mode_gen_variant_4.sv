//SystemVerilog
module multi_mode_gen #(
    parameter MODE_WIDTH = 2
)(
    input clk,
    input rst_n,
    input [MODE_WIDTH-1:0] mode,
    input [15:0] param,
    input data_valid_in,
    output reg data_valid_out,
    output reg signal_out
);

// 流水线寄存器
reg [15:0] counter;
reg [15:0] counter_stage1;
reg [MODE_WIDTH-1:0] mode_stage1;
reg [15:0] param_stage1;
reg valid_stage1;

// 中间结果寄存器 - 合并到一个统一的结果寄存器
reg [3:0] signal_results;

// 流水线第二级寄存器
reg [MODE_WIDTH-1:0] mode_stage2;
reg valid_stage2;

// 计数器逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 16'd0;
    end else begin
        counter <= counter + 1;
    end
end

// 流水线第一级 - 输入寄存和计算准备
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter_stage1 <= 16'd0;
        mode_stage1 <= {MODE_WIDTH{1'b0}};
        param_stage1 <= 16'd0;
        valid_stage1 <= 1'b0;
    end else begin
        counter_stage1 <= counter;
        mode_stage1 <= mode;
        param_stage1 <= param;
        valid_stage1 <= data_valid_in;
    end
end

// 流水线第二级 - 各种模式计算
// 使用位操作和多路复用器结构替代多个独立比较
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        signal_results <= 4'b0;
        valid_stage2 <= 1'b0;
        mode_stage2 <= {MODE_WIDTH{1'b0}};
    end else begin
        // 使用向量赋值统一处理结果
        // 比较优化: 使用相同位宽的比较操作
        signal_results[0] <= (counter_stage1 < param_stage1);                 // PWM模式
        signal_results[1] <= (counter_stage1 == 16'd0);                       // 单脉冲模式
        signal_results[2] <= ((counter_stage1 >> param_stage1[3:0]) & 1'b1);  // 分频模式优化
        signal_results[3] <= ^(counter_stage1[15:8] & counter_stage1[7:0]);   // 随机模式优化
        
        valid_stage2 <= valid_stage1;
        mode_stage2 <= mode_stage1;
    end
end

// 流水线第三级 - 使用查找表结构替代case语句
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        signal_out <= 1'b0;
        data_valid_out <= 1'b0;
    end else begin
        data_valid_out <= valid_stage2;
        
        // 优化: 使用查找表结构替代case语句
        signal_out <= signal_results[mode_stage2];
    end
end

endmodule