//SystemVerilog
module spread_spectrum_clk(
    input clock_in,
    input reset,
    input enable_spread,
    input [3:0] spread_amount,
    output reg clock_out
);
    // 阶段1: 计数和时钟生成
    reg [3:0] counter_stage1, period_stage1;
    reg direction_stage1;
    reg clock_out_stage1;
    reg counter_reset_stage1;
    
    // 阶段2: 周期调整
    reg [3:0] counter_stage2, period_stage2;
    reg direction_stage2;
    reg clock_out_stage2;
    
    // 阶段3: 最终输出
    reg [3:0] period_stage3;
    reg direction_stage3;
    
    // 控制信号
    reg valid_stage1, valid_stage2;
    
    // 阶段1: 计数器逻辑和时钟切换
    always @(posedge clock_in or posedge reset) begin
        if (reset) begin
            counter_stage1 <= 4'b0;
            period_stage1 <= 4'd8;
            direction_stage1 <= 1'b0;
            clock_out_stage1 <= 1'b0;
            counter_reset_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= 1'b1;
            
            if (counter_stage1 >= period_stage1) begin
                counter_stage1 <= 4'b0;
                clock_out_stage1 <= ~clock_out_stage1;
                counter_reset_stage1 <= 1'b1;
            end else begin
                counter_stage1 <= counter_stage1 + 4'b1;
                counter_reset_stage1 <= 1'b0;
            end
        end
    end
    
    // 阶段2: 周期调整逻辑
    always @(posedge clock_in or posedge reset) begin
        if (reset) begin
            period_stage2 <= 4'd8;
            direction_stage2 <= 1'b0;
            clock_out_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            valid_stage2 <= 1'b1;
            clock_out_stage2 <= clock_out_stage1;
            
            if (counter_reset_stage1) begin
                // 周期调整逻辑
                if (enable_spread && direction_stage1 && period_stage1 < 4'd8 + spread_amount) begin
                    period_stage2 <= period_stage1 + 4'd1;
                    direction_stage2 <= direction_stage1;
                end else if (enable_spread && direction_stage1 && period_stage1 >= 4'd8 + spread_amount) begin
                    period_stage2 <= period_stage1;
                    direction_stage2 <= 1'b0;
                end else if (enable_spread && !direction_stage1 && period_stage1 > 4'd8 - spread_amount) begin
                    period_stage2 <= period_stage1 - 4'd1;
                    direction_stage2 <= direction_stage1;
                end else if (enable_spread && !direction_stage1 && period_stage1 <= 4'd8 - spread_amount) begin
                    period_stage2 <= period_stage1;
                    direction_stage2 <= 1'b1;
                end else if (!enable_spread) begin
                    period_stage2 <= 4'd8;
                    direction_stage2 <= direction_stage1;
                end else begin
                    period_stage2 <= period_stage1;
                    direction_stage2 <= direction_stage1;
                end
            end else begin
                period_stage2 <= period_stage1;
                direction_stage2 <= direction_stage1;
            end
        end
    end
    
    // 阶段3: 最终输出和前递
    always @(posedge clock_in or posedge reset) begin
        if (reset) begin
            period_stage3 <= 4'd8;
            direction_stage3 <= 1'b0;
            clock_out <= 1'b0;
        end else if (valid_stage2) begin
            period_stage3 <= period_stage2;
            direction_stage3 <= direction_stage2;
            clock_out <= clock_out_stage2;
            
            // 将更新后的值前递到第一级流水线
            counter_stage1 <= counter_stage1;
            period_stage1 <= period_stage2;
            direction_stage1 <= direction_stage2;
        end
    end
endmodule