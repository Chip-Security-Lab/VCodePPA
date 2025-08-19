//SystemVerilog
module sync_enable_clock_gate (
    input  wire clk_in,
    input  wire rst_n,
    input  wire enable,
    output wire clk_out
);
    reg enable_latch;
    
    // 使用透明锁存器捕获使能信号，避免毛刺
    always @(*) begin
        if (!clk_in) begin
            enable_latch = enable;
        end
    end
    
    // 异步复位逻辑与时钟门控
    assign clk_out = rst_n ? (clk_in & enable_latch) : 1'b0;
    
endmodule