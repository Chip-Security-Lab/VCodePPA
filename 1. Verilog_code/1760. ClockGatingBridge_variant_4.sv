//SystemVerilog
// 定义时钟门控使能模块
module EnableLatch(
    input clk,
    input activity,
    output reg enable_latch
);
    always @(posedge clk) begin
        enable_latch <= activity | enable_latch;
    end
endmodule

// 定义时钟门控模块
module ClockGating(
    input clk,
    input enable_latch,
    output gated_clk
);
    assign gated_clk = clk & enable_latch;
endmodule

// 顶层模块
module ClockGatingBridge(
    input clk,
    input rst_n,
    input activity,
    output gated_clk
);
    wire enable_latch;

    // 实例化使能锁存器
    EnableLatch enable_latch_inst (
        .clk(clk),
        .activity(activity),
        .enable_latch(enable_latch)
    );

    // 实例化时钟门控模块
    ClockGating clock_gating_inst (
        .clk(clk),
        .enable_latch(enable_latch),
        .gated_clk(gated_clk)
    );
endmodule