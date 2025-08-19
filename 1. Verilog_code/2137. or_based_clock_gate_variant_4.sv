//SystemVerilog
//IEEE 1364-2005 Verilog
// 顶层模块 - 优化的基于OR的时钟门控
module or_based_clock_gate (
    input  wire clk_in,      // 输入时钟
    input  wire disable_n,    // 低电平有效的禁用信号
    output wire clk_out      // 门控后的输出时钟
);
    // 内部信号声明
    reg  disable_n_sync1;     // 同步的禁用信号阶段1
    reg  disable_n_sync2;     // 同步的禁用信号阶段2
    wire disable_signal;     // 处理后的禁用信号
    reg  clk_gate_ctrl;      // 时钟门控控制信号
    
    // 阶段1a: 输入信号同步第一级 (降低亚稳态风险)
    always @(posedge clk_in) begin
        disable_n_sync1 <= disable_n;
    end
    
    // 阶段1b: 输入信号同步第二级 (进一步降低亚稳态风险)
    always @(posedge clk_in) begin
        disable_n_sync2 <= disable_n_sync1;
    end
    
    // 阶段2: 禁用信号生成
    disable_signal_generator disable_gen (
        .disable_n_sync(disable_n_sync2),
        .disable_signal(disable_signal)
    );
    
    // 阶段3: 时钟门控控制信号准备
    always @(posedge clk_in) begin
        clk_gate_ctrl <= disable_signal;
    end
    
    // 阶段4: 时钟门控逻辑
    clock_gating_logic clk_gate (
        .clk_in(clk_in),
        .clk_gate_ctrl(clk_gate_ctrl),
        .clk_out(clk_out)
    );
endmodule

// 子模块：优化的禁用信号生成器
module disable_signal_generator (
    input  wire disable_n_sync,   // 同步后的禁用信号
    output wire disable_signal    // 生成的禁用信号
);
    // 使用连续赋值替代always块，更清晰地表达组合逻辑
    assign disable_signal = ~disable_n_sync;
endmodule

// 子模块：优化的时钟门控逻辑
module clock_gating_logic (
    input  wire clk_in,        // 输入时钟
    input  wire clk_gate_ctrl, // 时钟门控控制信号
    output wire clk_out        // 门控后的输出时钟
);
    // 使用OR门实现时钟门控
    assign clk_out = clk_in | clk_gate_ctrl;
endmodule