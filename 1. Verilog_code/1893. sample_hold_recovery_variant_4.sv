//SystemVerilog
module sample_hold_recovery (
    input wire clk,
    input wire sample_enable,
    input wire [11:0] analog_input,
    output reg [11:0] held_value,
    output reg hold_active
);
    // 将输入直接连接到组合逻辑，减少输入到寄存器的延迟
    reg sample_enable_reg;
    reg [11:0] analog_input_reg;
    
    // 在时钟上升沿对输入信号进行采样
    always @(posedge clk) begin
        sample_enable_reg <= sample_enable;
        analog_input_reg <= analog_input;
    end
    
    // 使用寄存器采样后的信号进行处理逻辑
    always @(posedge clk) begin
        if (sample_enable_reg) begin
            held_value <= analog_input_reg;
            hold_active <= 1'b1;
        end else begin
            hold_active <= 1'b1; // Continue holding
        end
    end
endmodule