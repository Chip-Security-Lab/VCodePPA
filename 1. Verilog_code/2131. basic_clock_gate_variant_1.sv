//SystemVerilog IEEE 1364-2005
// 顶层模块 - 集成时钟门控系统
module basic_clock_gate #(
    parameter ENABLE_SYNC_STAGES = 2  // 参数化设计，提高可配置性
)(
    input  wire clk_in,      // 输入时钟
    input  wire enable,      // 使能信号
    output wire clk_out      // 输出时钟
);
    // 内部信号定义
    wire enable_synced;      // 同步后的使能信号
    wire pre_gated_clock;    // 预门控时钟信号
    wire gated_clock;        // 门控后的时钟信号
    
    // 同步使能信号，防止亚稳态
    enable_synchronizer #(
        .SYNC_STAGES(ENABLE_SYNC_STAGES)
    ) u_enable_sync (
        .clk        (clk_in),
        .async_enable(enable),
        .sync_enable (enable_synced)
    );
    
    // 时钟门控核心逻辑
    clock_gating_cell u_clock_gate (
        .clk      (clk_in),
        .enable   (enable_synced),
        .gated_clk(pre_gated_clock)
    );
    
    // 时钟信号调节和优化
    clock_conditioning u_clock_cond (
        .clk_in  (pre_gated_clock),
        .clk_out (gated_clock)
    );
    
    // 输出驱动缓冲
    clock_output_driver u_out_driver (
        .clk_in  (gated_clock),
        .clk_out (clk_out)
    );
    
endmodule

// 使能信号同步模块 - 防止亚稳态
module enable_synchronizer #(
    parameter SYNC_STAGES = 2  // 可配置同步级数
)(
    input  wire clk,            // 时钟输入
    input  wire async_enable,   // 异步使能输入
    output wire sync_enable     // 同步使能输出
);
    // 同步寄存器链
    reg [SYNC_STAGES-1:0] sync_reg;
    
    always_ff @(posedge clk) begin
        sync_reg <= {sync_reg[SYNC_STAGES-2:0], async_enable};
    end
    
    assign sync_enable = sync_reg[SYNC_STAGES-1];
endmodule

// 时钟门控单元 - 实现高效门控逻辑
module clock_gating_cell (
    input  wire clk,        // 输入时钟
    input  wire enable,     // 使能信号
    output wire gated_clk   // 门控时钟输出
);
    // 使用锁存器风格的门控以防止毛刺
    reg enable_latch;
    
    always_latch begin
        if (!clk)
            enable_latch <= enable;
    end
    
    // AND门控制
    assign gated_clk = clk & enable_latch;
endmodule

// 时钟信号调节模块 - 优化时钟特性
module clock_conditioning (
    input  wire clk_in,    // 输入时钟
    output wire clk_out    // 调节后的时钟
);
    // 可在此添加时钟偏斜调整、抖动减少等功能
    // 此简单实现直接传递信号
    assign clk_out = clk_in;
endmodule

// 时钟输出驱动 - 提供足够的驱动能力
module clock_output_driver (
    input  wire clk_in,    // 输入时钟
    output wire clk_out    // 缓冲后的输出时钟
);
    // 多级缓冲实现，提高驱动能力
    wire [1:0] buffer_stages;
    
    assign buffer_stages[0] = clk_in;       // 第一级缓冲
    assign buffer_stages[1] = buffer_stages[0]; // 第二级缓冲
    assign clk_out = buffer_stages[1];      // 最终输出
endmodule