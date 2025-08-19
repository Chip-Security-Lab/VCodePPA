//SystemVerilog
module deadtime_timer (
    input wire clk, rst_n,
    input wire [15:0] period, duty,
    input wire [7:0] deadtime,
    output reg pwm_high, pwm_low
);
    reg [15:0] counter;
    wire compare_match;
    
    // 条件反相减法器实现的信号
    wire [15:0] period_minus_one;
    wire [15:0] period_minus_duty;
    wire [15:0] period_minus_deadtime;
    wire [15:0] counter_plus_one;
    
    // 条件反相减法器实现
    wire [15:0] not_period = ~period;
    wire [15:0] not_duty = ~duty;
    wire [15:0] not_deadtime = {8'hFF, ~deadtime};
    wire [15:0] not_counter = ~counter;
    
    // period_minus_one = period - 1 (使用条件反相减法器)
    assign period_minus_one = period + 16'hFFFF;
    
    // period_minus_duty = period - duty (使用条件反相减法器)
    assign period_minus_duty = period + not_duty + 16'h0001;
    
    // period_minus_deadtime = period - deadtime (使用条件反相减法器)
    assign period_minus_deadtime = period + not_deadtime + 16'h0001;
    
    // counter_plus_one = counter + 1 (递增计数器)
    assign counter_plus_one = counter + 16'h0001;
    
    // 合并具有相同触发条件的always块
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 16'd0;
            pwm_high <= 1'b0;
            pwm_low <= 1'b0;
        end
        else begin
            // 计数器逻辑 - 使用条件反相减法器计算的结果
            counter <= (counter >= period_minus_one) ? 16'd0 : counter_plus_one;
            
            // PWM输出逻辑
            pwm_high <= compare_match & (counter >= deadtime);
            pwm_low <= ~compare_match & (counter >= period_minus_deadtime || 
                      counter < period_minus_duty);
        end
    end
    
    // 比较逻辑保持不变
    assign compare_match = (counter < duty);
    
endmodule