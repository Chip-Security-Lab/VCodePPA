//SystemVerilog
module multi_mode_gen #(
    parameter MODE_WIDTH = 2
)(
    input clk,
    input [MODE_WIDTH-1:0] mode,
    input [15:0] param,
    output reg signal_out
);
    // 计数器及中间信号定义
    reg [15:0] counter;
    
    // 模式处理的寄存器
    reg pwm_output;
    reg pulse_output;
    reg divider_output;
    reg random_output;
    
    // 数据处理的中间寄存器
    reg [3:0] divider_select;
    reg [7:0] random_bits;
    
    // 计数器逻辑 - 独立always块
    always @(posedge clk) begin
        counter <= counter + 1'b1;
    end
    
    // PWM模式信号生成 - 独立always块
    always @(posedge clk) begin
        pwm_output <= (counter < param);
    end
    
    // 单脉冲模式信号生成 - 独立always块
    always @(posedge clk) begin
        pulse_output <= (counter == 16'd0);
    end
    
    // 分频选择寄存器更新 - 独立always块
    always @(posedge clk) begin
        divider_select <= param[3:0];
    end
    
    // 分频模式信号生成 - 独立always块
    always @(posedge clk) begin
        divider_output <= counter[divider_select];
    end
    
    // 随机位捕获 - 独立always块
    always @(posedge clk) begin
        random_bits <= counter[15:8];
    end
    
    // 随机模式信号生成 - 独立always块
    always @(posedge clk) begin
        random_output <= ^random_bits;
    end
    
    // 输出多路复用器 - 独立always块
    always @(posedge clk) begin
        case(mode)
            2'b00: signal_out <= pwm_output;
            2'b01: signal_out <= pulse_output;
            2'b10: signal_out <= divider_output;
            2'b11: signal_out <= random_output;
            default: signal_out <= 1'b0;
        endcase
    end
endmodule