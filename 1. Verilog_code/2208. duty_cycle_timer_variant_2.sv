//SystemVerilog

// 顶层模块
module duty_cycle_timer #(
    parameter WIDTH = 12
)(
    input clk,
    input reset,
    input [WIDTH-1:0] period,
    input [7:0] duty_percent, // 0-100%
    output pwm_out
);
    // 内部连线
    wire [WIDTH-1:0] duty_ticks;
    wire [WIDTH-1:0] period_minus_one;
    wire [WIDTH-1:0] counter_value;
    wire pwm_next;

    // 预计算单元子模块
    duty_calculator #(
        .WIDTH(WIDTH)
    ) duty_calc_inst (
        .clk(clk),
        .reset(reset),
        .period(period),
        .duty_percent(duty_percent),
        .duty_ticks(duty_ticks),
        .period_minus_one(period_minus_one)
    );

    // 计数器子模块
    pwm_counter #(
        .WIDTH(WIDTH)
    ) counter_inst (
        .clk(clk),
        .reset(reset),
        .period_minus_one(period_minus_one),
        .counter_value(counter_value)
    );

    // 比较器子模块
    pwm_comparator #(
        .WIDTH(WIDTH)
    ) comp_inst (
        .clk(clk),
        .reset(reset),
        .counter_value(counter_value),
        .duty_ticks(duty_ticks),
        .pwm_out(pwm_out)
    );
endmodule

// 预计算单元子模块
module duty_calculator #(
    parameter WIDTH = 12
)(
    input clk,
    input reset,
    input [WIDTH-1:0] period,
    input [7:0] duty_percent,
    output reg [WIDTH-1:0] duty_ticks,
    output reg [WIDTH-1:0] period_minus_one
);
    // 优化的预计算逻辑
    always @(posedge clk) begin
        if (reset) begin
            duty_ticks <= {WIDTH{1'b0}};
            period_minus_one <= {WIDTH{1'b0}};
        end else begin
            // 使用移位操作优化计算，减少面积和功耗
            duty_ticks <= (period * duty_percent) >> 7;
            period_minus_one <= period - 1'b1;
        end
    end
endmodule

// 计数器子模块
module pwm_counter #(
    parameter WIDTH = 12
)(
    input clk,
    input reset,
    input [WIDTH-1:0] period_minus_one,
    output reg [WIDTH-1:0] counter_value
);
    // 优化的计数器逻辑
    always @(posedge clk) begin
        if (reset) begin
            counter_value <= {WIDTH{1'b0}};
        end else begin
            // 使用预计算的period_minus_one比较，减少关键路径延迟
            counter_value <= (counter_value >= period_minus_one) ? {WIDTH{1'b0}} : (counter_value + 1'b1);
        end
    end
endmodule

// 比较器子模块
module pwm_comparator #(
    parameter WIDTH = 12
)(
    input clk,
    input reset,
    input [WIDTH-1:0] counter_value,
    input [WIDTH-1:0] duty_ticks,
    output reg pwm_out
);
    // PWM比较和输出逻辑
    wire pwm_next;
    
    // 组合逻辑比较部分
    assign pwm_next = (counter_value < duty_ticks) ? 1'b1 : 1'b0;
    
    // 输出寄存器
    always @(posedge clk) begin
        if (reset) begin
            pwm_out <= 1'b0;
        end else begin
            pwm_out <= pwm_next;
        end
    end
endmodule