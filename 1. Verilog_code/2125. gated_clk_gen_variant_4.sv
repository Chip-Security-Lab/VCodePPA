//SystemVerilog
/* IEEE 1364-2005 Verilog standard */
//====================================================================
// 顶层模块: 时钟门控生成器(优化版)
//====================================================================
module gated_clk_gen (
    input  wire main_clk,  // 主时钟输入
    input  wire gate_en,   // 门控使能信号
    output wire gated_clk   // 门控后的时钟输出
);

    // 内部信号声明
    reg enable_latched;

    // 实现透明锁存器 - 集成原enable_latch功能
    // 当main_clk为低电平时，锁存enable值
    always @(*) begin
        if (!main_clk)
            enable_latched = gate_en;
    end

    // 门控时钟生成 - 直接实现而非通过子模块
    assign gated_clk = main_clk & enable_latched;

endmodule