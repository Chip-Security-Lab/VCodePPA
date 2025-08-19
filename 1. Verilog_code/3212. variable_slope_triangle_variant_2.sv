//SystemVerilog
module variable_slope_triangle(
    input clk_in,
    input reset,
    input [7:0] up_slope_rate,
    input [7:0] down_slope_rate,
    output reg [7:0] triangle_out
);

    // 流水线阶段1 - 计数和比较
    reg direction_stage1;  // 0 = up, 1 = down
    reg [7:0] counter_stage1;
    reg [7:0] triangle_stage1;
    reg counter_reset_stage1;
    reg update_value_stage1;
    
    // 流水线阶段2 - 计算新值
    reg direction_stage2;
    reg [7:0] triangle_stage2;
    reg update_direction_stage2;

    // 优化比较逻辑
    wire [7:0] rate_threshold;
    wire rate_match;
    
    // 选择当前方向的速率阈值
    assign rate_threshold = direction_stage1 ? down_slope_rate : up_slope_rate;
    
    // 使用减法比较替代大于等于比较
    assign rate_match = (counter_stage1 >= rate_threshold);
    
    // 第一阶段流水线 - 计数和比较
    always @(posedge clk_in) begin
        if (reset) begin
            counter_stage1 <= 8'b0;
            direction_stage1 <= 1'b0;
            triangle_stage1 <= 8'b0;
            counter_reset_stage1 <= 1'b0;
            update_value_stage1 <= 1'b0;
        end else begin
            // 默认状态
            counter_reset_stage1 <= 1'b0;
            update_value_stage1 <= 1'b0;
            triangle_stage1 <= triangle_out;
            
            // 增加计数器
            if (counter_reset_stage1)
                counter_stage1 <= 8'b0;
            else
                counter_stage1 <= counter_stage1 + 8'b1;
            
            // 使用优化的比较逻辑
            if (rate_match) begin
                counter_reset_stage1 <= 1'b1;
                update_value_stage1 <= 1'b1;
            end
        end
    end
    
    // 第二阶段流水线 - 更新三角波和方向
    always @(posedge clk_in) begin
        if (reset) begin
            direction_stage2 <= 1'b0;
            triangle_stage2 <= 8'b0;
            update_direction_stage2 <= 1'b0;
            triangle_out <= 8'b0;
        end else begin
            // 传递信号到下一级
            direction_stage2 <= direction_stage1;
            update_direction_stage2 <= 1'b0;
            
            // 基于第一阶段的决定更新值
            if (update_value_stage1) begin
                if (!direction_stage1) begin
                    if (triangle_stage1 == 8'hff) begin
                        update_direction_stage2 <= 1'b1;
                        triangle_stage2 <= triangle_stage1;
                    end else begin
                        triangle_stage2 <= triangle_stage1 + 8'b1;
                    end
                end else begin
                    if (triangle_stage1 == 8'h00) begin
                        update_direction_stage2 <= 1'b1;
                        triangle_stage2 <= triangle_stage1;
                    end else begin
                        triangle_stage2 <= triangle_stage1 - 8'b1;
                    end
                end
            end else begin
                triangle_stage2 <= triangle_stage1;
            end
            
            // 更新最终输出
            triangle_out <= triangle_stage2;
            
            // 更新方向
            if (update_direction_stage2) begin
                direction_stage1 <= ~direction_stage2;
            end
        end
    end
endmodule