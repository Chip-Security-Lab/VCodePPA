//SystemVerilog
// 顶层模块
module preset_ring_counter(
    input  wire       clk,
    input  wire       rst,
    input  wire       preset,
    output wire [3:0] q
);
    // 内部连线
    wire [1:0] ctrl_signals;
    wire [3:0] next_q;
    reg  [3:0] q_reg;
    
    // 控制信号生成子模块
    control_decoder control_unit (
        .rst(rst),
        .preset(preset),
        .ctrl_signals(ctrl_signals)
    );
    
    // 下一状态逻辑子模块
    next_state_logic next_state_unit (
        .q_current(q_reg),
        .ctrl_signals(ctrl_signals),
        .q_next(next_q)
    );
    
    // 寄存器更新逻辑
    always @(posedge clk) begin
        q_reg <= next_q;
    end
    
    // 输出赋值
    assign q = q_reg;
    
endmodule

// 控制信号解码器子模块
module control_decoder(
    input  wire       rst,
    input  wire       preset,
    output wire [1:0] ctrl_signals
);
    // 简单地组合rst和preset信号
    assign ctrl_signals = {rst, preset};
endmodule

// 下一状态逻辑子模块
module next_state_logic(
    input  wire [3:0] q_current,
    input  wire [1:0] ctrl_signals,
    output reg  [3:0] q_next
);
    // 基于控制信号和当前状态确定下一状态
    always @(*) begin
        case(ctrl_signals)
            2'b10, 2'b11: q_next = 4'b0001; // 复位优先级最高
            2'b01:        q_next = 4'b1000; // 预置值
            2'b00:        q_next = {q_current[2:0], q_current[3]}; // 正常移位
            default:      q_next = 4'b0001; // 安全默认值
        endcase
    end
endmodule