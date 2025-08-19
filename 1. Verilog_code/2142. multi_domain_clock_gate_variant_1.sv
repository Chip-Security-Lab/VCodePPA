//SystemVerilog - IEEE 1364-2005
module multi_domain_clock_gate (
    input  wire clk_a,
    input  wire clk_b,
    input  wire en_a,
    input  wire en_b,
    output wire gated_clk_a,
    output wire gated_clk_b
);
    // 实例化正极性时钟门控模块
    clock_gate_positive u_clk_gate_a (
        .clk_in  (clk_a),
        .enable  (en_a),
        .clk_out (gated_clk_a)
    );
    
    // 实例化负极性时钟门控模块
    clock_gate_negative u_clk_gate_b (
        .clk_in  (clk_b),
        .enable  (en_b),
        .clk_out (gated_clk_b)
    );
    
endmodule

// 正极性时钟门控子模块
module clock_gate_positive (
    input  wire clk_in,
    input  wire enable,
    output wire clk_out
);
    // 参数化设计，方便未来扩展或配置
    parameter BUFFER_EN = 0;
    
    // 扁平化正极性门控逻辑
    wire clk_gated;
    
    assign clk_gated = (BUFFER_EN == 1) ? (clk_in & enable) : clk_in & enable;
    assign clk_out = clk_gated;
    
endmodule

// 负极性时钟门控子模块
module clock_gate_negative (
    input  wire clk_in,
    input  wire enable,
    output wire clk_out
);
    // 参数化设计，方便未来扩展或配置
    parameter BUFFER_EN = 0;
    
    // 扁平化负极性门控逻辑
    wire enable_n = ~enable;
    wire clk_gated;
    
    assign clk_gated = (BUFFER_EN == 1) ? (clk_in & enable_n) : clk_in & enable_n;
    assign clk_out = clk_gated;
    
endmodule