//SystemVerilog
module window_comparator_range_detector(
    input wire clk,                  // 添加时钟信号用于流水线寄存器
    input wire rst_n,                // 添加复位信号
    input wire [9:0] analog_value,
    input wire [9:0] window_center,
    input wire [9:0] window_width,
    output reg in_window             // 改为寄存器输出，支持流水线
);
    // 第一级流水线: 计算阈值
    reg [9:0] half_width_r;
    reg [9:0] lower_threshold_r;
    reg [9:0] upper_threshold_r;
    reg [9:0] analog_value_r;
    
    // 第二级流水线: 进行比较
    reg lower_compare_r;
    reg upper_compare_r;
    
    // 第一级流水线逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            half_width_r <= 10'b0;
            lower_threshold_r <= 10'b0;
            upper_threshold_r <= 10'b0;
            analog_value_r <= 10'b0;
        end else begin
            half_width_r <= window_width >> 1;
            lower_threshold_r <= window_center - half_width_r;
            upper_threshold_r <= window_center + half_width_r;
            analog_value_r <= analog_value;
        end
    end
    
    // 第二级流水线逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lower_compare_r <= 1'b0;
            upper_compare_r <= 1'b0;
        end else begin
            lower_compare_r <= (analog_value_r >= lower_threshold_r);
            upper_compare_r <= (analog_value_r <= upper_threshold_r);
        end
    end
    
    // 第三级流水线逻辑 - 最终结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_window <= 1'b0;
        end else begin
            in_window <= lower_compare_r && upper_compare_r;
        end
    end
endmodule