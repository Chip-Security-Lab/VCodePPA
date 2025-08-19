//SystemVerilog
module gated_clk_gen(
    input  wire main_clk,
    input  wire gate_en,
    output wire gated_clk
);
    reg latch_en_signal;
    
    // 直接在主模块中实现低功耗时钟门控
    // 使用透明锁存器在时钟低电平时捕获使能信号
    always @(main_clk or gate_en) begin
        if (!main_clk)
            latch_en_signal <= gate_en;
    end
    
    // 直接组合时钟和锁存的使能信号
    assign gated_clk = main_clk & latch_en_signal;
endmodule