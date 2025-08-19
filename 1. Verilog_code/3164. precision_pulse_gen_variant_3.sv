//SystemVerilog
/////////////////////////////////////////////////////////////
// 顶层模块：精确脉冲发生器
/////////////////////////////////////////////////////////////
module precision_pulse_gen #(
    parameter CLK_FREQ_HZ = 100000000,
    parameter PULSE_US = 10
)(
    input clk,
    input rst_n,
    input trigger,
    output pulse_out
);
    // 本地参数计算
    localparam COUNT = (CLK_FREQ_HZ / 1000000) * PULSE_US;
    localparam CNT_WIDTH = $clog2(COUNT);
    
    // 内部连接信号
    wire start_pulse;
    wire timeout;
    wire [CNT_WIDTH-1:0] count_limit = COUNT - 1;
    
    // 触发检测模块实例化
    trigger_detector u_trigger_detector (
        .clk(clk),
        .rst_n(rst_n),
        .trigger(trigger),
        .active(active),
        .start_pulse(start_pulse)
    );
    
    // 脉冲计数器模块实例化
    pulse_counter #(
        .CNT_WIDTH(CNT_WIDTH)
    ) u_pulse_counter (
        .clk(clk),
        .rst_n(rst_n),
        .start_pulse(start_pulse),
        .count_limit(count_limit),
        .active(active),
        .timeout(timeout)
    );
    
    // 脉冲输出控制模块实例化
    pulse_controller u_pulse_controller (
        .clk(clk),
        .rst_n(rst_n),
        .start_pulse(start_pulse),
        .timeout(timeout),
        .pulse_out(pulse_out),
        .active(active)
    );
    
endmodule

/////////////////////////////////////////////////////////////
// 触发检测模块：检测输入触发信号并生成启动脉冲
/////////////////////////////////////////////////////////////
module trigger_detector (
    input clk,
    input rst_n,
    input trigger,
    input active,
    output reg start_pulse
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_pulse <= 1'b0;
        end else begin
            start_pulse <= trigger && !active;
        end
    end
endmodule

/////////////////////////////////////////////////////////////
// 脉冲计数器模块：计数所需的脉冲宽度
/////////////////////////////////////////////////////////////
module pulse_counter #(
    parameter CNT_WIDTH = 10
)(
    input clk,
    input rst_n,
    input start_pulse,
    input [CNT_WIDTH-1:0] count_limit,
    output reg active,
    output reg timeout
);
    reg [CNT_WIDTH-1:0] counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= {CNT_WIDTH{1'b0}};
            active <= 1'b0;
            timeout <= 1'b0;
        end else if (start_pulse) begin
            counter <= {CNT_WIDTH{1'b0}};
            active <= 1'b1;
            timeout <= 1'b0;
        end else if (active) begin
            timeout <= 1'b0;
            if (counter == count_limit) begin
                timeout <= 1'b1;
                active <= 1'b0;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end
endmodule

/////////////////////////////////////////////////////////////
// 脉冲输出控制模块：根据计时状态控制输出脉冲
/////////////////////////////////////////////////////////////
module pulse_controller (
    input clk,
    input rst_n,
    input start_pulse,
    input timeout,
    output reg pulse_out,
    output active
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pulse_out <= 1'b0;
        end else if (start_pulse) begin
            pulse_out <= 1'b1;
        end else if (timeout) begin
            pulse_out <= 1'b0;
        end
    end
endmodule