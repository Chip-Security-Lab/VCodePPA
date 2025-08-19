//SystemVerilog
module pulse_demux (
    input  wire       clk,         // 系统时钟
    input  wire       pulse_in,    // 输入脉冲
    input  wire [1:0] route_sel,   // 路由选择
    output reg  [3:0] pulse_out    // 输出脉冲
);
    // 寄存器定义
    reg pulse_prev;                // 上一个脉冲状态
    
    // 组合逻辑信号
    wire pulse_edge;               // 上升沿检测
    wire [3:0] next_pulse_out;     // 输出脉冲的下一状态
    
    // 上升沿检测
    assign pulse_edge = pulse_in && !pulse_prev;
    
    // 桶形移位器结构实现
    // 使用多路复用器替代变量移位
    assign next_pulse_out[0] = pulse_edge & (route_sel == 2'b00);
    assign next_pulse_out[1] = pulse_edge & (route_sel == 2'b01);
    assign next_pulse_out[2] = pulse_edge & (route_sel == 2'b10);
    assign next_pulse_out[3] = pulse_edge & (route_sel == 2'b11);
    
    // 时序逻辑部分
    always @(posedge clk) begin
        // 更新上一个脉冲状态
        pulse_prev <= pulse_in;
        
        // 更新输出脉冲
        pulse_out <= next_pulse_out;
    end
endmodule