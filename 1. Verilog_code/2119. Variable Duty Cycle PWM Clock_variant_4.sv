//SystemVerilog
module var_duty_pwm_clk #(
    parameter PERIOD = 16
)(
    input clk_in,
    input rst,
    input [3:0] duty,  // 0-15 (0%-93.75%)
    output reg clk_out
);
    // 定义常量
    localparam CNT_WIDTH = $clog2(PERIOD);
    
    // 流水线寄存器
    reg [CNT_WIDTH-1:0] counter_stage1;
    reg [CNT_WIDTH-1:0] counter_stage2;
    reg [3:0] duty_stage1;
    reg [3:0] duty_stage2;
    
    // 流水线控制信号
    reg valid_stage1;
    reg valid_stage2;
    
    // 中间结果
    reg counter_eq_period_stage1;
    reg counter_lt_duty_stage1;
    
    // 阶段1: 计数器逻辑和比较操作
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            counter_stage1 <= 0;
            duty_stage1 <= 0;
            valid_stage1 <= 0;
            counter_eq_period_stage1 <= 0;
            counter_lt_duty_stage1 <= 0;
        end else begin
            // 保存当前输入到阶段1寄存器
            duty_stage1 <= duty;
            valid_stage1 <= 1'b1;
            
            // 计数器递增逻辑
            if (counter_stage1 < PERIOD-1) begin
                counter_stage1 <= counter_stage1 + 1'b1;
                counter_eq_period_stage1 <= 1'b0;
            end else begin
                counter_stage1 <= 0;
                counter_eq_period_stage1 <= 1'b1;
            end
            
            // 比较计数器和占空比
            counter_lt_duty_stage1 <= (counter_stage1 < duty_stage1);
        end
    end
    
    // 阶段2: PWM输出生成
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            counter_stage2 <= 0;
            duty_stage2 <= 0;
            valid_stage2 <= 0;
            clk_out <= 0;
        end else begin
            // 将阶段1的值传递到阶段2
            counter_stage2 <= counter_eq_period_stage1 ? 0 : counter_stage1 + 1'b1;
            duty_stage2 <= duty_stage1;
            valid_stage2 <= valid_stage1;
            
            // 生成PWM输出
            if (valid_stage2) begin
                clk_out <= counter_lt_duty_stage1;
            end else begin
                clk_out <= 1'b0;
            end
        end
    end
endmodule