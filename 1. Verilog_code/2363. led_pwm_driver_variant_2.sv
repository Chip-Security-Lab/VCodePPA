//SystemVerilog
// 顶层模块
module led_pwm_driver #(
    parameter W = 8
)(
    input wire clk,
    input wire [W-1:0] duty,
    output wire pwm_out
);
    // 内部连线
    wire [W-1:0] counter_value;
    
    // 计数器子模块实例化
    pwm_counter #(
        .WIDTH(W)
    ) counter_inst (
        .clk(clk),
        .counter_out(counter_value)
    );
    
    // 比较器子模块实例化 - 使用条件反相减法器算法
    pwm_comparator #(
        .WIDTH(W)
    ) comparator_inst (
        .clk(clk),
        .counter_value(counter_value),
        .duty_cycle(duty),
        .pwm_out(pwm_out)
    );
    
endmodule

// 计数器子模块
module pwm_counter #(
    parameter WIDTH = 8
)(
    input wire clk,
    output reg [WIDTH-1:0] counter_out
);
    // 自由运行的计数器
    always @(posedge clk) begin
        counter_out <= counter_out + 1'b1;
    end
endmodule

// 比较器子模块 - 使用条件反相减法器算法实现
module pwm_comparator #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire [WIDTH-1:0] counter_value,
    input wire [WIDTH-1:0] duty_cycle,
    output reg pwm_out
);
    // 条件反相减法器实现
    reg [WIDTH:0] subtraction_result;
    reg borrow;
    reg [WIDTH-1:0] minuend, subtrahend, result;
    reg invert;
    
    always @(posedge clk) begin
        // 确定操作数和是否需要反相
        if (counter_value >= duty_cycle) begin
            minuend = counter_value;
            subtrahend = duty_cycle;
            invert = 1'b0;  // 不需要反相
        end else begin
            minuend = duty_cycle;
            subtrahend = counter_value;
            invert = 1'b1;  // 需要反相
        end
        
        // 条件反相减法
        {borrow, result} = {1'b0, minuend} - {1'b0, subtrahend};
        
        // 根据减法结果设置pwm输出
        pwm_out <= invert ? 1'b1 : 1'b0;
    end
endmodule