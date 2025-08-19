//SystemVerilog
//===================================================================
// 顶层模块：可变占空比PWM时钟生成器
//===================================================================
module var_duty_pwm_clk #(
    parameter PERIOD = 16
)(
    input clk_in,
    input rst,
    input [3:0] duty,  // 0-15 (0%-93.75%)
    output wire clk_out
);
    // 内部连线信号
    wire [$clog2(PERIOD)-1:0] counter_value;
    wire counter_reset;
    
    // 计数器子模块实例化
    pwm_counter #(
        .PERIOD(PERIOD)
    ) counter_inst (
        .clk_in(clk_in),
        .rst(rst),
        .counter_value(counter_value),
        .counter_reset(counter_reset)
    );
    
    // 比较器子模块实例化
    pwm_comparator #(
        .PERIOD(PERIOD)
    ) comparator_inst (
        .clk_in(clk_in),
        .rst(rst),
        .counter_value(counter_value),
        .duty(duty),
        .clk_out(clk_out)
    );
    
endmodule

//===================================================================
// 计数器子模块：生成周期性计数值
//===================================================================
module pwm_counter #(
    parameter PERIOD = 16
)(
    input clk_in,
    input rst,
    output reg [$clog2(PERIOD)-1:0] counter_value,
    output wire counter_reset
);
    // 计数器复位信号生成
    assign counter_reset = (counter_value == PERIOD-1);
    
    // 计数器逻辑
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            counter_value <= 0;
        end else begin
            if (counter_reset) begin
                counter_value <= 0;
            end else begin
                counter_value <= counter_value + 1;
            end
        end
    end
endmodule

//===================================================================
// 比较器子模块：比较计数值与占空比，生成PWM输出
//===================================================================
module pwm_comparator #(
    parameter PERIOD = 16
)(
    input clk_in,
    input rst,
    input [$clog2(PERIOD)-1:0] counter_value,
    input [3:0] duty,
    output reg clk_out
);
    // 比较逻辑
    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            clk_out <= 0;
        end else begin
            if (counter_value < duty) begin
                clk_out <= 1'b1;
            end else begin
                clk_out <= 1'b0;
            end
        end
    end
endmodule