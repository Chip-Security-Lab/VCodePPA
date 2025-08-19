//SystemVerilog
module diff_clk_buffer (
    input  wire single_ended_clk,  // 单端时钟输入
    output wire clk_p,             // 差分正相输出
    output wire clk_n              // 差分负相输出
);
    // 应用前向寄存器重定时策略 - 直接生成差分输出
    // 移除了不必要的中间信号和寄存器，优化时序路径
    
    // 直接从输入生成差分输出 - 无额外寄存器延迟
    assign clk_p = single_ended_clk;
    assign clk_n = ~single_ended_clk;

endmodule