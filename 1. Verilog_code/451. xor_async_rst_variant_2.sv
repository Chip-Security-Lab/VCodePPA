//SystemVerilog
// 顶层模块 - 优化后的设计
module xor_async_rst(
    input clk,
    input rst_n,
    input a,
    input b,
    output y
);
    // 直接连接，移除了中间信号和子模块层次
    reg y_reg;
    assign y = y_reg;
    
    // 整合逻辑和寄存器，减少信号传播延迟
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            y_reg <= 1'b0;
        else
            y_reg <= a ^ b; // XOR操作直接在寄存器逻辑中实现
    end
    
endmodule