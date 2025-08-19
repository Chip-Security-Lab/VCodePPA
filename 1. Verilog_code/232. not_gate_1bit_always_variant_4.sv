//SystemVerilog
// 顶层模块
module not_gate_1bit_top (
    input wire clk,        // 时钟信号
    input wire rst_n,      // 复位信号
    input wire A,          // 输入信号
    output reg Y           // 输出信号，现在为寄存器输出
);
    // 内部连线
    wire inv_logic_out;
    
    // 实例化逻辑子模块 - 直接连接到输入A，移除了输入寄存器
    not_gate_logic_core logic_unit (
        .in_signal(A),
        .out_signal(inv_logic_out)
    );
    
    // 将寄存器移动到输出端，应用前向寄存器重定时
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            Y <= inv_logic_out;
        end
    end
    
endmodule

// 逻辑核心子模块 - 实现逻辑功能
module not_gate_logic_core (
    input wire in_signal,
    output wire out_signal
);
    // 使用连续赋值而非always块，优化组合逻辑
    assign out_signal = ~in_signal;
    
endmodule