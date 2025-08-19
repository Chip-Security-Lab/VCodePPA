//SystemVerilog
// 顶层模块
module pwm_generator #(
    parameter WIDTH = 8,
    parameter PERIOD = 100
)(
    input clk,
    input [WIDTH-1:0] duty,
    output pwm_out
);
    // 内部连线
    wire [WIDTH-1:0] counter_value;
    wire period_end;
    
    // 实例化计数器子模块
    counter_module #(
        .WIDTH(WIDTH),
        .PERIOD(PERIOD)
    ) counter_inst (
        .clk(clk),
        .counter_value(counter_value),
        .period_end(period_end)
    );
    
    // 实例化比较器子模块
    comparator_module #(
        .WIDTH(WIDTH)
    ) comparator_inst (
        .clk(clk),
        .counter_value(counter_value),
        .duty(duty),
        .pwm_out(pwm_out)
    );
endmodule

// 计数器子模块
module counter_module #(
    parameter WIDTH = 8,
    parameter PERIOD = 100
)(
    input clk,
    output reg [WIDTH-1:0] counter_value,
    output period_end
);
    // 流水线寄存器
    reg [WIDTH-1:0] counter_next;
    reg period_end_next;
    
    // 计数器逻辑
    initial begin
        counter_value = 0;
        counter_next = 0;
    end
    
    // 组合逻辑计算下一状态
    always @(*) begin
        if (counter_value == PERIOD) begin
            counter_next = 0;
            period_end_next = 1'b1;
        end else begin
            counter_next = counter_value + 1'b1;
            period_end_next = 1'b0;
        end
    end
    
    // 时序逻辑更新状态
    always @(posedge clk) begin
        counter_value <= counter_next;
    end
    
    // 输出寄存器
    reg period_end_reg;
    always @(posedge clk) begin
        period_end_reg <= period_end_next;
    end
    
    assign period_end = period_end_reg;
endmodule

// 比较器子模块
module comparator_module #(
    parameter WIDTH = 8
)(
    input clk,
    input [WIDTH-1:0] counter_value,
    input [WIDTH-1:0] duty,
    output reg pwm_out
);
    // 流水线寄存器
    reg [WIDTH-1:0] counter_value_reg;
    reg [WIDTH-1:0] duty_reg;
    reg compare_result;
    
    // 输入寄存器
    always @(posedge clk) begin
        counter_value_reg <= counter_value;
        duty_reg <= duty;
    end
    
    // 比较逻辑
    always @(*) begin
        compare_result = (counter_value_reg < duty_reg);
    end
    
    // 输出寄存器
    always @(posedge clk) begin
        pwm_out <= compare_result;
    end
endmodule