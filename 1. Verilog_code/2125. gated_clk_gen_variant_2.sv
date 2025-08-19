//SystemVerilog
// 顶层模块
module gated_clk_gen (
    input  wire main_clk,
    input  wire gate_en,
    output wire gated_clk
);
    // 内部连线
    wire enable_latched;
    
    // 实例化使能信号锁存子模块
    enable_latch enable_latch_inst (
        .clk     (main_clk),
        .enable  (gate_en),
        .latched (enable_latched)
    );
    
    // 实例化时钟门控子模块
    clock_gate clock_gate_inst (
        .clk         (main_clk),
        .enable      (enable_latched),
        .gated_clock (gated_clk)
    );
    
endmodule

// 使能信号锁存子模块
module enable_latch (
    input  wire clk,     // 主时钟
    input  wire enable,  // 使能输入
    output reg  latched  // 锁存后的使能
);
    // 在时钟下降沿锁存使能信号，防止毛刺
    always @(negedge clk) begin
        latched <= enable;
    end
endmodule

// 时钟门控子模块
module clock_gate (
    input  wire clk,         // 主时钟
    input  wire enable,      // 锁存后的使能信号
    output wire gated_clock  // 门控后的时钟输出
);
    // 使用与门组合生成门控时钟
    assign gated_clock = clk & enable;
endmodule