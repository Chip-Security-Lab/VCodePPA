//SystemVerilog
module hierarchical_clock_gate (
    input  wire master_clk,  // 主时钟输入
    input  wire global_en,   // 全局使能
    input  wire local_en,    // 局部使能
    output wire block_clk    // 门控后的时钟输出
);
    // 阶段1: 使能信号预处理
    reg  enable_stage1;
    
    // 阶段2: 时钟门控
    reg  enable_stage2;
    
    // 流水线化使能信号路径
    always @(posedge master_clk or negedge global_en) begin
        if (!global_en)
            enable_stage1 <= 1'b0;
        else
            enable_stage1 <= local_en;
    end
    
    // 使能信号延迟匹配
    always @(posedge master_clk) begin
        enable_stage2 <= enable_stage1;
    end
    
    // 时钟门控实现
    // 使用可综合的门控单元
    CLOCK_GATE_CELL clock_gate_inst (
        .CLK(master_clk),
        .EN(enable_stage2),
        .GCLK(block_clk)
    );
    
    // 模拟时钟门控单元（当工具链不支持特定门控单元时使用）
    // assign block_clk = master_clk & enable_stage2;
    
endmodule

// 时钟门控单元（可被ASIC或FPGA工具替换为专用门控单元）
module CLOCK_GATE_CELL (
    input  wire CLK,  // 输入时钟
    input  wire EN,   // 使能信号
    output wire GCLK  // 门控后的时钟
);
    reg latch_en;
    
    // 使用锁存器捕获使能信号，减少毛刺风险
    always @(*) begin
        if (!CLK)
            latch_en = EN;
    end
    
    // 实现门控
    assign GCLK = CLK & latch_en;
endmodule