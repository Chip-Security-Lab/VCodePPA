//SystemVerilog
// 顶层模块: 时钟门控控制器
module latch_based_clock_gate (
    input  wire clk_in,
    input  wire enable,
    output wire clk_out
);
    // 内部连线
    wire enable_latched;
    
    // 低电平透明锁存器实现
    level_sensitive_latch u_latch (
        .clk_n      (~clk_in),
        .data_in    (enable),
        .latch_out  (enable_latched)
    );
    
    // 时钟输出控制实现
    clock_output_control u_clock_control (
        .clk_in     (clk_in),
        .enable_in  (enable_latched),
        .gated_clk  (clk_out)
    );
    
endmodule

// 子模块1: 优化的低电平透明锁存器
module level_sensitive_latch (
    input  wire clk_n,     // 低电平有效时钟信号
    input  wire data_in,   // 数据输入
    output reg  latch_out  // 锁存器输出
);
    // 优化后的锁存器实现，使用阻塞赋值提高效率
    // 当clk_n为低电平时传递数据
    always @(*) begin
        if (!clk_n)
            latch_out = data_in;
    end
endmodule

// 子模块2: 优化的时钟输出控制
module clock_output_control (
    input  wire clk_in,    // 输入时钟
    input  wire enable_in, // 使能信号
    output wire gated_clk  // 门控后的时钟输出
);
    // 优化的时钟门控逻辑
    assign gated_clk = enable_in ? clk_in : 1'b0;
endmodule