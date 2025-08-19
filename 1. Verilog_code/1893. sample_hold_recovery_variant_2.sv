//SystemVerilog
module sample_hold_recovery (
    input wire clk,
    input wire sample_enable,
    input wire [11:0] analog_input,
    output reg [11:0] held_value,
    output reg hold_active
);
    // 后向寄存器重定时优化 - 将寄存器移到组合逻辑之前
    // 保存采样使能信号的历史值
    reg sample_enable_d;
    
    // 直接使用输入信号，避免额外的寄存器延迟
    always @(posedge clk) begin
        sample_enable_d <= sample_enable;
        
        if (sample_enable) begin
            held_value <= analog_input;
        end
        
        // 更新保持状态 - 当前采样状态或继续保持
        hold_active <= sample_enable || hold_active;
    end
endmodule