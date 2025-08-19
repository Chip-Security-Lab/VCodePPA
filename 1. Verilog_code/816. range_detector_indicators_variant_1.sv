//SystemVerilog
module range_detector_indicators(
    input wire clk,                      // 添加时钟输入
    input wire rst_n,                    // 添加复位输入
    input wire [11:0] input_value,
    input wire [11:0] min_threshold, max_threshold,
    output reg in_range,
    output reg below_range,
    output reg above_range
);
    // 第一级流水线 - 计算比较结果
    reg [11:0] input_value_r;
    reg [11:0] min_threshold_r, max_threshold_r;
    reg below_range_stage1, above_range_stage1;
    
    // 第二级流水线 - 派生最终结果
    reg below_range_stage2, above_range_stage2;
    
    // 数据路径第一级 - 寄存输入并执行比较
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_value_r <= 12'd0;
            min_threshold_r <= 12'd0;
            max_threshold_r <= 12'd0;
            below_range_stage1 <= 1'b0;
            above_range_stage1 <= 1'b0;
        end else begin
            input_value_r <= input_value;
            min_threshold_r <= min_threshold;
            max_threshold_r <= max_threshold;
            below_range_stage1 <= (input_value < min_threshold);
            above_range_stage1 <= (input_value > max_threshold);
        end
    end
    
    // 数据路径第二级 - 转发比较结果并计算in_range
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            below_range_stage2 <= 1'b0;
            above_range_stage2 <= 1'b0;
            below_range <= 1'b0;
            above_range <= 1'b0;
            in_range <= 1'b0;
        end else begin
            below_range_stage2 <= below_range_stage1;
            above_range_stage2 <= above_range_stage1;
            below_range <= below_range_stage2;
            above_range <= above_range_stage2;
            in_range <= !(below_range_stage2 || above_range_stage2);
        end
    end
endmodule