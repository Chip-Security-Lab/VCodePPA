//SystemVerilog
// 顶层模块
module hierarchical_clock_gate (
    input  wire master_clk,
    input  wire global_en,
    input  wire local_en,
    output wire block_clk
);
    // 内部信号
    wire enable_signal;
    
    // 实例化使能控制子模块
    enable_controller en_ctrl (
        .global_enable(global_en),
        .local_enable(local_en),
        .combined_enable(enable_signal)
    );
    
    // 实例化时钟门控子模块
    clock_gater clk_gate (
        .clock_in(master_clk),
        .enable(enable_signal),
        .gated_clock(block_clk)
    );
    
endmodule

// 使能控制子模块 - 处理各级使能信号的组合
module enable_controller (
    input  wire global_enable,
    input  wire local_enable,
    output wire combined_enable
);
    // 组合两个使能信号
    assign combined_enable = global_enable & local_enable;
endmodule

// 时钟门控子模块 - 处理时钟与使能的组合
module clock_gater (
    input  wire clock_in,
    input  wire enable,
    output wire gated_clock
);
    // 应用时钟门控
    assign gated_clock = clock_in & enable;
endmodule