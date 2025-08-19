//SystemVerilog
module pulse2level_ismu(
    input wire clock,
    input wire reset_n,
    input wire [3:0] pulse_interrupt,
    input wire clear,
    output reg [3:0] level_interrupt
);
    // 直接计算控制信号，无需寄存器化
    wire [1:0] ctrl_current;
    reg [1:0] ctrl_stage1;
    reg [3:0] pulse_interrupt_delayed;
    reg [3:0] level_interrupt_next;
    
    // 控制信号组合逻辑计算
    assign ctrl_current = (!reset_n) ? 2'b00 :
                         (clear) ? 2'b10 : 2'b01;
    
    // 第一阶段流水线 - 寄存控制信号和中断信号
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            ctrl_stage1 <= 2'b00;
            pulse_interrupt_delayed <= 4'h0;
        end else begin
            ctrl_stage1 <= ctrl_current;
            pulse_interrupt_delayed <= pulse_interrupt;
        end
    end
    
    // 第二阶段流水线 - 中断处理逻辑计算
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            level_interrupt_next <= 4'h0;
        end else begin
            case(ctrl_stage1)
                2'b00: level_interrupt_next <= 4'h0;                                 // 复位状态
                2'b01: level_interrupt_next <= level_interrupt | pulse_interrupt_delayed; // 正常操作
                2'b10: level_interrupt_next <= 4'h0;                                 // 清除中断
                default: level_interrupt_next <= 4'h0;                               // 安全状态
            endcase
        end
    end
    
    // 第三阶段流水线 - 输出寄存
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            level_interrupt <= 4'h0;
        end else begin
            level_interrupt <= level_interrupt_next;
        end
    end
    
endmodule