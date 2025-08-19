//SystemVerilog
module hierarchical_clock_gate (
    input  wire master_clk,
    input  wire global_en,
    input  wire local_en,
    output wire block_clk
);
    // 使用标准的时钟门控单元实现
    // 先合并使能信号，再通过专用时钟门控单元产生门控时钟
    wire combined_en;
    reg  latched_en;
    
    // 合并全局和局部使能信号
    assign combined_en = global_en & local_en;
    
    // 在时钟的负边沿锁存使能信号，避免毛刺
    always @(negedge master_clk or negedge combined_en)
        if (!combined_en)
            latched_en <= 1'b0;
        else
            latched_en <= combined_en;
    
    // 使用锁存的使能信号生成门控时钟
    assign block_clk = master_clk & latched_en;
endmodule