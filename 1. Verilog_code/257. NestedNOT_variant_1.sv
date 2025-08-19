//SystemVerilog
module NestedNOT(
    input  wire clk,     // 时钟信号输入
    input  wire rst_n,   // 复位信号输入
    input  wire sig,     // 数据输入信号
    output wire out      // 数据输出信号
);
    // 内部信号声明
    reg sig_registered;  // 寄存器
    
    // 输入寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sig_registered <= 1'b0;
        else
            sig_registered <= sig;
    end
    
    // 输出逻辑 - 简化了连续两个NOT的逻辑
    // ~(~sig_registered) 等于 sig_registered
    assign out = sig_registered;
    
endmodule