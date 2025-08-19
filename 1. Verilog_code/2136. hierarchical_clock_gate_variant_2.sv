//SystemVerilog
module hierarchical_clock_gate (
    input  wire master_clk,
    input  wire global_en,
    input  wire local_en,
    output wire block_clk
);
    // 优化后直接使用单一赋值，减少中间信号和逻辑级数
    // 使用AND运算符直接组合所有使能信号
    assign block_clk = master_clk & global_en & local_en;
endmodule