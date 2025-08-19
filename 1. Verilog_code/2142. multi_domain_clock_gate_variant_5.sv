//SystemVerilog
module multi_domain_clock_gate (
    input  wire clk_a,
    input  wire clk_b,
    input  wire en_a,
    input  wire en_b,
    output wire gated_clk_a,
    output wire gated_clk_b
);
    // 为两个时钟域声明锁存器信号
    reg en_a_latch, en_b_latch;
    
    // 时钟域A的锁存器实现
    always @(clk_a or en_a)
        if (!clk_a) en_a_latch <= en_a;
        
    // 时钟域B的锁存器实现
    always @(clk_b or en_b)
        if (!clk_b) en_b_latch <= ~en_b; // 维持反相极性
    
    // 使用与门实现门控时钟
    assign gated_clk_a = clk_a & en_a_latch;
    assign gated_clk_b = clk_b & en_b_latch;
    
endmodule