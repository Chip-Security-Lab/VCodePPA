//SystemVerilog
module pulse2level_ismu(
    input  wire        clock,
    input  wire        reset_n,
    input  wire [3:0]  pulse_interrupt,
    input  wire        clear,
    output wire [3:0]  level_interrupt
);

    // 内部信号 - 将输入pulse_interrupt寄存器化
    reg [3:0] pulse_interrupt_reg;
    
    // 寄存化输入信号，移动到组合逻辑之前
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            pulse_interrupt_reg <= 4'h0;
        end
        else begin
            pulse_interrupt_reg <= pulse_interrupt;
        end
    end
    
    // 中断状态寄存器
    reg [3:0] interrupt_status;
    
    // 将重置和清除逻辑保留，但使用寄存化的输入信号
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            interrupt_status <= 4'h0;
        end
        else if (clear) begin
            interrupt_status <= 4'h0;
        end
        else begin
            interrupt_status <= interrupt_status | pulse_interrupt_reg;
        end
    end
    
    // 直接将中断状态作为输出，移除额外的输出寄存器级
    assign level_interrupt = interrupt_status;
    
endmodule