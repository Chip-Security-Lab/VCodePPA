//SystemVerilog
module clock_gate (
    input clk,
    input enable,
    output gated_clk
);
    reg latch_enable;
    
    // 使用透明锁存器替代组合逻辑，避免毛刺
    always @(clk or enable) begin
        if (!clk) latch_enable = enable;
    end
    
    // 时钟与使能信号的与门操作
    assign gated_clk = clk & latch_enable;
endmodule