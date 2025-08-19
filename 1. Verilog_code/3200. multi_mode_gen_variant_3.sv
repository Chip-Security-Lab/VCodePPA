//SystemVerilog
//-------------顶层模块-------------
module multi_mode_gen #(
    parameter MODE_WIDTH = 2
)(
    input clk,
    input [MODE_WIDTH-1:0] mode,
    input [15:0] param,
    output signal_out
);
    // 共享计数器信号
    wire [15:0] counter;
    
    // 模式输出信号
    wire pwm_out;
    wire single_pulse_out;
    wire divider_out;
    wire random_out;
    
    // 公共计数器模块
    counter_module counter_inst (
        .clk(clk),
        .counter(counter)
    );
    
    // PWM模式生成模块
    pwm_generator pwm_inst (
        .counter(counter),
        .param(param),
        .pwm_out(pwm_out)
    );
    
    // 单脉冲模式生成模块
    single_pulse_generator single_pulse_inst (
        .counter(counter),
        .single_pulse_out(single_pulse_out)
    );
    
    // 分频模式生成模块
    divider_generator divider_inst (
        .counter(counter),
        .param(param[3:0]),
        .divider_out(divider_out)
    );
    
    // 随机模式生成模块
    random_generator random_inst (
        .counter(counter[15:8]),
        .random_out(random_out)
    );
    
    // 模式选择器模块
    mode_selector #(.MODE_WIDTH(MODE_WIDTH)) mode_select_inst (
        .mode(mode),
        .pwm_out(pwm_out),
        .single_pulse_out(single_pulse_out),
        .divider_out(divider_out),
        .random_out(random_out),
        .signal_out(signal_out)
    );

endmodule

//-------------计数器模块-------------
module counter_module (
    input clk,
    output reg [15:0] counter
);
    initial begin
        counter = 16'd0;
    end
    
    always @(posedge clk) begin
        counter <= counter + 1'b1;
    end
endmodule

//-------------PWM生成器模块-------------
module pwm_generator (
    input [15:0] counter,
    input [15:0] param,
    output pwm_out
);
    // PWM模式：当计数器小于参数值时输出高电平
    assign pwm_out = (counter < param);
endmodule

//-------------单脉冲生成器模块-------------
module single_pulse_generator (
    input [15:0] counter,
    output single_pulse_out
);
    // 单脉冲模式：仅在计数器为0时输出高电平
    assign single_pulse_out = (counter == 16'd0);
endmodule

//-------------分频生成器模块-------------
module divider_generator (
    input [15:0] counter,
    input [3:0] param,
    output divider_out
);
    // 分频模式：根据参数选择特定的计数器位作为输出
    assign divider_out = counter[param];
endmodule

//-------------随机生成器模块-------------
module random_generator (
    input [7:0] counter,
    output random_out
);
    // 随机模式：计数器高8位的奇偶校验作为输出
    assign random_out = ^counter;
endmodule

//-------------模式选择器模块-------------
module mode_selector #(
    parameter MODE_WIDTH = 2
)(
    input [MODE_WIDTH-1:0] mode,
    input pwm_out,
    input single_pulse_out,
    input divider_out,
    input random_out,
    output reg signal_out
);
    always @(*) begin
        case(mode)
            2'b00: signal_out = pwm_out;          // PWM模式
            2'b01: signal_out = single_pulse_out; // 单脉冲模式
            2'b10: signal_out = divider_out;      // 分频模式
            2'b11: signal_out = random_out;       // 随机模式
            default: signal_out = 1'b0;
        endcase
    end
endmodule