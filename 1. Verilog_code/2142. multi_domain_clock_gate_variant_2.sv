//SystemVerilog
// 顶层模块
module multi_domain_clock_gate (
    input  wire clk_a,
    input  wire clk_b,
    input  wire en_a,
    input  wire en_b,
    output wire gated_clk_a,
    output wire gated_clk_b
);
    // 实例化优化后的时钟门控子模块
    clock_gate #(
        .POSITIVE_ENABLE(1),
        .TECH_LIBRARY("DEFAULT")
    ) domain_a (
        .clk_in    (clk_a),
        .enable    (en_a),
        .gated_clk (gated_clk_a)
    );

    clock_gate #(
        .POSITIVE_ENABLE(0),
        .TECH_LIBRARY("DEFAULT")
    ) domain_b (
        .clk_in    (clk_b),
        .enable    (en_b),
        .gated_clk (gated_clk_b)
    );
endmodule

// 统一的参数化时钟门控模块
module clock_gate #(
    parameter POSITIVE_ENABLE = 1,  // 1:正极性使能, 0:负极性使能
    parameter TECH_LIBRARY = "DEFAULT"
)(
    input  wire clk_in,
    input  wire enable,
    output wire gated_clk
);
    // 内部信号
    wire effective_enable;
    
    // 根据极性参数确定有效使能信号
    assign effective_enable = POSITIVE_ENABLE ? enable : ~enable;
    
    // 根据工艺库选择不同实现
    generate
        if (TECH_LIBRARY == "FPGA") begin
            // FPGA优化实现，添加锁存器以避免毛刺
            reg enable_latch;
            
            always @(clk_in or effective_enable)
                if (!clk_in)  // 在时钟低电平时锁存使能信号
                    enable_latch <= effective_enable;
                    
            assign gated_clk = clk_in & enable_latch;
        end
        else begin
            // 默认实现
            assign gated_clk = clk_in & effective_enable;
        end
    endgenerate
endmodule