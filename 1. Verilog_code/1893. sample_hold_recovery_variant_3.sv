//SystemVerilog
module sample_hold_recovery (
    input wire clk,
    input wire sample_enable,
    input wire [11:0] analog_input,
    output reg [11:0] held_value,
    output reg hold_active
);
    // 采样逻辑控制块 - 仅在sample_enable有效时更新held_value
    always @(posedge clk) begin
        if (sample_enable) begin
            held_value <= analog_input;
        end
    end
    
    // 保持状态控制块 - 专门管理hold_active信号
    always @(posedge clk) begin
        hold_active <= 1'b1;
    end
endmodule