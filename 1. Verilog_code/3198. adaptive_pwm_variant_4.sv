//SystemVerilog
module adaptive_pwm #(
    parameter WIDTH = 8
)(
    input clk,
    input feedback,
    output reg pwm
);

// 数据路径寄存器
reg [WIDTH-1:0] duty_cycle_reg;
reg [WIDTH-1:0] counter_reg;
reg [1:0] state_reg;

// 组合逻辑信号
wire [1:0] next_state;
wire [WIDTH-1:0] next_duty_cycle;
wire pwm_output;

// 状态编码逻辑
assign next_state = {feedback, (duty_cycle_reg == 8'hFF) || (duty_cycle_reg == 8'h00)};

// 占空比更新逻辑
assign next_duty_cycle = (next_state == 2'b00) ? duty_cycle_reg - 1 :
                        (next_state == 2'b01) ? duty_cycle_reg :
                        (next_state == 2'b10) ? duty_cycle_reg + 1 :
                        duty_cycle_reg;

// PWM输出逻辑
assign pwm_output = (counter_reg < duty_cycle_reg);

// 时序逻辑
always @(posedge clk) begin
    // 计数器更新
    counter_reg <= counter_reg + 1;
    
    // 状态寄存器更新
    state_reg <= next_state;
    
    // 占空比寄存器更新
    duty_cycle_reg <= next_duty_cycle;
    
    // PWM输出寄存器更新
    pwm <= pwm_output;
end

endmodule