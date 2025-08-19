//SystemVerilog
module duty_cycle_timer #(
    parameter WIDTH = 12
)(
    input clk,
    input reset,
    input [WIDTH-1:0] period,
    input [7:0] duty_percent, // 0-100%
    output reg pwm_out
);
    reg [WIDTH-1:0] counter;
    reg [WIDTH-1:0] period_reg;
    reg [7:0] duty_percent_reg;
    wire [WIDTH-1:0] duty_ticks;
    wire [WIDTH-1:0] period_minus_one;
    wire period_compare;
    
    // 在输入处添加寄存器，减少输入到第一级寄存器的延迟
    always @(posedge clk) begin
        if (reset) begin
            period_reg <= {WIDTH{1'b0}};
            duty_percent_reg <= 8'h0;
        end else begin
            period_reg <= period;
            duty_percent_reg <= duty_percent;
        end
    end
    
    // 条件反相减法器实现
    // 计算period-1
    wire carry_out;
    wire [WIDTH-1:0] inverted_one = ~{{(WIDTH-1){1'b0}}, 1'b1};
    assign {carry_out, period_minus_one} = period_reg + inverted_one + 1'b1;
    
    // Convert percent to ticks
    assign duty_ticks = (period_reg * duty_percent_reg) / 8'd100;
    
    // 使用条件反相减法器进行比较
    wire [WIDTH-1:0] counter_inv = ~counter;
    wire [WIDTH:0] compare_result = {1'b0, period_minus_one} + {1'b0, counter_inv} + 1'b1;
    assign period_compare = ~compare_result[WIDTH];
    
    // 组合逻辑的结果
    wire counter_lt_duty = (counter < duty_ticks);
    
    always @(posedge clk) begin
        if (reset) begin
            counter <= {WIDTH{1'b0}};
            pwm_out <= 1'b0;
        end else begin
            if (period_compare) begin
                counter <= {WIDTH{1'b0}};
            end else begin
                counter <= counter + 1'b1;
            end
            
            // 将比较逻辑的结果寄存，而非在always块内计算
            pwm_out <= counter_lt_duty;
        end
    end
endmodule