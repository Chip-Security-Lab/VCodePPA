//SystemVerilog
//IEEE 1364-2005
module pwm_timer #(
    parameter COUNTER_WIDTH = 12
)(
    input clk_i,
    input rst_n_i,
    input [COUNTER_WIDTH-1:0] period_i,
    input [COUNTER_WIDTH-1:0] duty_i,
    output reg pwm_o
);
    // 内部信号声明
    reg [COUNTER_WIDTH-1:0] counter;
    
    // 状态信号
    wire duty_is_zero = (duty_i == {COUNTER_WIDTH{1'b0}});
    wire counter_is_zero = (counter == {COUNTER_WIDTH{1'b0}});
    wire end_of_period = (counter >= period_i - 1'b1);
    wire duty_reached = (counter >= duty_i - 1'b1) && !duty_is_zero;
    
    // 计数器控制逻辑
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            counter <= {COUNTER_WIDTH{1'b0}};
        end else begin
            counter <= end_of_period ? {COUNTER_WIDTH{1'b0}} : counter + 1'b1;
        end
    end
    
    // PWM输出控制逻辑
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            pwm_o <= 1'b0;
        end else if (end_of_period || counter_is_zero) begin
            // 在周期开始时设置PWM高电平（除非占空比为0）
            pwm_o <= !duty_is_zero;
        end else if (duty_reached) begin
            // 当达到占空比时将PWM设为低电平
            pwm_o <= 1'b0;
        end
    end
endmodule