//SystemVerilog
module sleep_mode_clock_gate (
    input  wire sys_clk,    // 系统时钟
    input  wire sleep_req,  // 睡眠请求信号
    input  wire wake_event, // 唤醒事件信号
    input  wire rst_n,      // 低电平有效的复位信号
    output wire core_clk    // 输出到核心的时钟
);
    reg sleep_state;
    wire next_sleep_state;
    
    // 预计算下一个睡眠状态，分离组合逻辑和时序逻辑
    // 使用逻辑等价变换减少组合路径深度
    assign next_sleep_state = sleep_state ? ~wake_event : (sleep_req & ~wake_event);
    
    // 睡眠状态控制逻辑
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n)
            sleep_state <= 1'b0;
        else
            sleep_state <= next_sleep_state;
    end
    
    // 使用时钟门控单元来生成核心时钟
    assign core_clk = sys_clk & ~sleep_state;
endmodule