//SystemVerilog
//-----------------------------------------------------------------------------
// File: prescaler_timer_top.v
// Project: 定时器系统
// Description: 可配置的预分频定时器顶层模块 (优化版)
// Standard: IEEE 1364-2005 Verilog
//-----------------------------------------------------------------------------
module PrescalerTimer #(
    parameter PRESCALE = 8
) (
    input  wire clk,    // 系统时钟
    input  wire rst_n,  // 低电平有效复位
    output wire tick    // 定时脉冲输出
);

    // 计数器值
    wire [$clog2(PRESCALE)-1:0] counter_value;
    // 计数器最大值标志
    wire counter_max;

    // 实例化计数器子模块
    PrescalerCounter #(
        .PRESCALE(PRESCALE)
    ) counter_inst (
        .clk           (clk),
        .rst_n         (rst_n),
        .counter_value (counter_value),
        .counter_max   (counter_max)
    );

    // 实例化脉冲生成器子模块
    TickGenerator tick_gen_inst (
        .clk         (clk),
        .rst_n       (rst_n),
        .counter_max (counter_max),
        .tick        (tick)
    );

endmodule

//-----------------------------------------------------------------------------
// 预分频计数器子模块
//-----------------------------------------------------------------------------
module PrescalerCounter #(
    parameter PRESCALE = 8
) (
    input  wire clk,
    input  wire rst_n,
    output reg  [$clog2(PRESCALE)-1:0] counter_value,
    output reg  counter_max
);

    // 组合逻辑部分 - 先计算下一状态
    wire [$clog2(PRESCALE)-1:0] next_counter;
    wire next_counter_max;
    
    assign next_counter_max = (counter_value == PRESCALE-2);
    assign next_counter = (counter_value == PRESCALE-1) ? 0 : counter_value + 1;

    // 寄存器重定时 - 将counter_max寄存器移动到组合逻辑之后
    always @(posedge clk) begin
        if (!rst_n) begin
            counter_value <= 0;
            counter_max <= 0;
        end else begin
            counter_value <= next_counter;
            counter_max <= next_counter_max;
        end
    end

endmodule

//-----------------------------------------------------------------------------
// 脉冲生成器子模块
//-----------------------------------------------------------------------------
module TickGenerator (
    input  wire clk,
    input  wire rst_n,
    input  wire counter_max,
    output reg  tick
);

    // 脉冲生成逻辑
    always @(posedge clk) begin
        if (!rst_n) begin
            tick <= 0;
        end else begin
            tick <= counter_max;
        end
    end

endmodule