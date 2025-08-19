//SystemVerilog
module pulse2level_ismu(
    input wire clock,
    input wire reset_n,
    input wire [3:0] pulse_interrupt,
    input wire clear,
    output reg [3:0] level_interrupt
);

    // 流水线寄存器和控制信号
    reg [3:0] pulse_interrupt_stage1;
    reg [3:0] level_interrupt_stage1;
    reg clear_stage1;
    reg valid_stage1;
    
    reg [3:0] interrupt_combined_stage2;
    reg valid_stage2;
    
    // 第一级流水线 - 捕获输入
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            pulse_interrupt_stage1 <= 4'h0;
            level_interrupt_stage1 <= 4'h0;
            clear_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else begin
            pulse_interrupt_stage1 <= pulse_interrupt;
            level_interrupt_stage1 <= level_interrupt;
            clear_stage1 <= clear;
            valid_stage1 <= 1'b1; // 输入始终有效
        end
    end
    
    // 第二级流水线 - 组合逻辑计算
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            interrupt_combined_stage2 <= 4'h0;
            valid_stage2 <= 1'b0;
        end
        else if (valid_stage1) begin
            if (clear_stage1)
                interrupt_combined_stage2 <= 4'h0;
            else
                interrupt_combined_stage2 <= level_interrupt_stage1 | pulse_interrupt_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线 - 输出寄存器
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            level_interrupt <= 4'h0;
        end
        else if (valid_stage2) begin
            level_interrupt <= interrupt_combined_stage2;
        end
    end
    
endmodule