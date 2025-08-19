//SystemVerilog
// 顶层模块 - 流水线PWM编码器
module pwm_codec #(
    parameter RES = 10
) (
    input  wire clk,
    input  wire rst,
    input  wire [RES-1:0] duty,
    input  wire valid_in,
    output wire valid_out,
    output wire pwm_out
);
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    
    // 内部流水线寄存器
    reg [RES-1:0] duty_stage1, duty_stage2;
    wire [RES-1:0] counter_value;
    reg [RES-1:0] counter_value_stage1;
    
    // 计数器子模块实例化
    pwm_counter #(
        .WIDTH(RES)
    ) counter_inst (
        .clk(clk),
        .rst(rst),
        .count(counter_value)
    );
    
    // 阶段1：寄存输入和计数器值
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            duty_stage1 <= {RES{1'b0}};
            counter_value_stage1 <= {RES{1'b0}};
            valid_stage1 <= 1'b0;
        end
        else begin
            duty_stage1 <= duty;
            counter_value_stage1 <= counter_value;
            valid_stage1 <= valid_in;
        end
    end
    
    // 阶段2：寄存比较的数据
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            duty_stage2 <= {RES{1'b0}};
            valid_stage2 <= 1'b0;
        end
        else begin
            duty_stage2 <= duty_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 比较器子模块实例化 - 流水线版本
    pwm_comparator #(
        .WIDTH(RES)
    ) comparator_inst (
        .clk(clk),
        .rst(rst),
        .counter_value(counter_value_stage1),
        .duty_cycle(duty_stage2),
        .valid_in(valid_stage2),
        .valid_out(valid_out),
        .pwm_out(pwm_out)
    );
    
endmodule

// 计数器子模块 - 优化版本
module pwm_counter #(
    parameter WIDTH = 10
) (
    input wire clk,
    input wire rst,
    output reg [WIDTH-1:0] count
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            count <= {WIDTH{1'b0}};
        else
            count <= count + 1'b1;
    end
endmodule

// 比较器子模块 - 流水线版本
module pwm_comparator #(
    parameter WIDTH = 10
) (
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] counter_value,
    input wire [WIDTH-1:0] duty_cycle,
    input wire valid_in,
    output reg valid_out,
    output reg pwm_out
);
    // 比较结果的中间寄存器
    reg compare_result;
    
    // 阶段1：执行比较逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            compare_result <= 1'b0;
            valid_out <= 1'b0;
        end
        else begin
            compare_result <= (counter_value < duty_cycle);
            valid_out <= valid_in;
        end
    end
    
    // 阶段2：寄存比较结果到输出
    always @(posedge clk or posedge rst) begin
        if (rst)
            pwm_out <= 1'b0;
        else
            pwm_out <= compare_result;
    end
endmodule