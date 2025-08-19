//SystemVerilog
module range_detector_indicators(
    input wire clk,
    input wire rst_n,
    input wire [11:0] input_value,
    input wire [11:0] min_threshold, max_threshold,
    output reg in_range,
    output reg below_range,
    output reg above_range
);

    // 第一级流水线寄存器
    reg comp_below_r, comp_above_r;
    
    // 第二级流水线寄存器
    reg below_range_i, above_range_i;
    
    // 第一级比较逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            comp_below_r <= 1'b0;
            comp_above_r <= 1'b0;
        end else begin
            comp_below_r <= (input_value < min_threshold);
            comp_above_r <= (input_value > max_threshold);
        end
    end
    
    // 第二级中间状态逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            below_range_i <= 1'b0;
            above_range_i <= 1'b0;
        end else begin
            below_range_i <= comp_below_r;
            above_range_i <= comp_above_r;
        end
    end
    
    // 第三级输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            below_range <= 1'b0;
            above_range <= 1'b0;
            in_range <= 1'b0;
        end else begin
            below_range <= below_range_i;
            above_range <= above_range_i;
            in_range <= !(below_range_i || above_range_i);
        end
    end

endmodule