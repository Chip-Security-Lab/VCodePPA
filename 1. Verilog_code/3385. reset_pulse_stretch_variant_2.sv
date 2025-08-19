//SystemVerilog
// 顶层模块
module reset_pulse_stretch #(
    parameter STRETCH_COUNT = 4
)(
    input wire clk,
    input wire reset_in,
    output wire reset_out
);
    // 内部连线
    wire reset_in_captured;
    wire [2:0] counter_value;
    wire reset_signal;
    wire valid_signal;

    // 实例化输入捕获子模块
    input_capture input_capture_inst (
        .clk(clk),
        .reset_in(reset_in),
        .reset_in_captured(reset_in_captured)
    );

    // 实例化计数器控制子模块
    counter_control #(
        .STRETCH_COUNT(STRETCH_COUNT)
    ) counter_control_inst (
        .clk(clk),
        .reset_in(reset_in_captured),
        .counter_value(counter_value),
        .reset_signal(reset_signal)
    );

    // 实例化输出生成子模块
    output_generator output_generator_inst (
        .clk(clk),
        .reset_signal(reset_signal),
        .counter_value(counter_value),
        .reset_out(reset_out)
    );
endmodule

// 输入捕获子模块
module input_capture (
    input wire clk,
    input wire reset_in,
    output reg reset_in_captured
);
    always @(posedge clk) begin
        reset_in_captured <= reset_in;
    end
endmodule

// 计数器控制子模块
module counter_control #(
    parameter STRETCH_COUNT = 4
)(
    input wire clk,
    input wire reset_in,
    output reg [2:0] counter_value,
    output reg reset_signal
);
    // 内部计数器寄存器
    reg [2:0] counter;

    always @(posedge clk) begin
        if (reset_in) begin
            counter <= STRETCH_COUNT;
            reset_signal <= 1'b1;
        end else if (counter > 0) begin
            counter <= counter - 1'b1;
            reset_signal <= 1'b1;
        end else begin
            counter <= 3'b0;
            reset_signal <= 1'b0;
        end
        
        counter_value <= counter;
    end
endmodule

// 输出生成子模块
module output_generator (
    input wire clk,
    input wire reset_signal,
    input wire [2:0] counter_value,
    output reg reset_out
);
    // 处理和缓冲寄存器
    reg reset_signal_d;
    reg [2:0] counter_value_d;
    reg valid_d;

    always @(posedge clk) begin
        // 缓冲输入信号
        reset_signal_d <= reset_signal;
        counter_value_d <= counter_value;
        valid_d <= 1'b1; // 此管道始终有效
        
        // 生成最终输出
        if (valid_d)
            reset_out <= reset_signal_d;
    end
endmodule