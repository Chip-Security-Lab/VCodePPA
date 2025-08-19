//SystemVerilog
// 顶层模块
module sync_enable_clock_gate (
    input  wire clk_in,
    input  wire rst_n,
    input  wire enable,
    output wire clk_out
);
    // 内部信号
    wire latch_out;
    
    // 子模块实例化
    enable_latch_module latch_inst (
        .clk_in       (clk_in),
        .enable       (enable),
        .enable_latch (latch_out)
    );
    
    clock_gating_module gate_inst (
        .clk_in       (clk_in),
        .enable_latch (latch_out),
        .clk_out      (clk_out)
    );
    
endmodule

// 锁存器子模块 - 处理使能信号锁存
module enable_latch_module (
    input  wire clk_in,
    input  wire enable,
    output reg  enable_latch
);
    // 当时钟为低电平时锁存使能信号
    always @(clk_in or enable) begin
        if (!clk_in)
            enable_latch <= enable;
    end
endmodule

// 时钟门控子模块 - 生成门控时钟
module clock_gating_module (
    input  wire clk_in,
    input  wire enable_latch,
    output wire clk_out
);
    // 生成门控时钟输出
    assign clk_out = clk_in & enable_latch;
endmodule