//SystemVerilog
module async_duty_pulse(
    input clk,
    input arst,
    input [7:0] period,
    input [2:0] duty_sel,  // 0-7 representing duty cycles
    output reg pulse
);
    // 流水线寄存器声明
    reg [7:0] counter_stage1;
    reg [7:0] counter_stage2;
    reg [7:0] duty_threshold_stage1;
    reg [7:0] duty_threshold_stage2;
    reg [7:0] period_stage1;
    reg [2:0] duty_sel_stage1;
    
    // 中间计算结果寄存器
    reg [7:0] half_period;
    reg [7:0] quarter_period;
    reg [7:0] eighth_period;
    
    // 第一级流水线 - 输入寄存和基本周期划分计算
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            period_stage1 <= 8'd0;
            duty_sel_stage1 <= 3'd0;
            half_period <= 8'd0;
            quarter_period <= 8'd0;
            eighth_period <= 8'd0;
        end else begin
            period_stage1 <= period;
            duty_sel_stage1 <= duty_sel;
            
            // 预计算常用的周期分数
            half_period <= {1'b0, period[7:1]};         // 50%
            quarter_period <= {2'b00, period[7:2]};     // 25%
            eighth_period <= {3'b000, period[7:3]};     // 12.5%
        end
    end
    
    // 第二级流水线 - 占空比阈值计算
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            duty_threshold_stage1 <= 8'd0;
        end else begin
            case (duty_sel_stage1)
                3'd0: duty_threshold_stage1 <= half_period;      // 50%
                3'd1: duty_threshold_stage1 <= quarter_period;   // 25%
                3'd2: duty_threshold_stage1 <= eighth_period;    // 12.5%
                3'd3: duty_threshold_stage1 <= quarter_period + half_period; // 75%
                3'd4: duty_threshold_stage1 <= eighth_period + half_period;  // 62.5%
                3'd5: duty_threshold_stage1 <= eighth_period + quarter_period; // 37.5%
                3'd6: duty_threshold_stage1 <= period_stage1 - 8'd1;   // 99%
                3'd7: duty_threshold_stage1 <= 8'd1;             // 1%
            endcase
        end
    end
    
    // 第三级流水线 - 计数器逻辑和寄存器传递
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            counter_stage1 <= 8'd0;
            duty_threshold_stage2 <= 8'd0;
        end else begin
            duty_threshold_stage2 <= duty_threshold_stage1;
            
            if (counter_stage1 >= period_stage1-1)
                counter_stage1 <= 8'd0;
            else
                counter_stage1 <= counter_stage1 + 8'd1;
        end
    end
    
    // 第四级流水线 - 脉冲输出比较和生成
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            counter_stage2 <= 8'd0;
            pulse <= 1'b0;
        end else begin
            counter_stage2 <= counter_stage1;
            pulse <= (counter_stage2 < duty_threshold_stage2) ? 1'b1 : 1'b0;
        end
    end
endmodule