//SystemVerilog
module sync_enable_clock_gate (
    input  wire clk_in,
    input  wire rst_n,
    input  wire enable,
    output wire clk_out
);
    reg enable_latch;
    
    // 使用锁存器替代寄存器，避免毛刺并改善时序
    always @(clk_in or enable or rst_n) begin
        if (!rst_n)
            enable_latch <= 1'b0;
        else if (!clk_in)  // 在时钟低电平时透明，高电平时保持
            enable_latch <= enable;
    end
    
    assign clk_out = clk_in & enable_latch;
endmodule