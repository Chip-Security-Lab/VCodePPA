//SystemVerilog
module ClockGatingBridge(
    input clk,
    input rst_n,
    input activity,
    output gated_clk
);
    wire enable_signal;

    // 实例化使能锁存器
    EnableLatch enable_latch_inst (
        .clk(clk),
        .activity(activity),
        .enable(enable_signal)
    );

    // 实例化时钟门控单元
    ClockGatingUnit clock_gating_unit_inst (
        .clk(clk),
        .enable(enable_signal),
        .gated_clk(gated_clk)
    );
endmodule

module EnableLatch(
    input clk,
    input activity,
    output reg enable
);
    // 时序逻辑部分
    always @(posedge clk or negedge activity) begin
        if (!activity)
            enable <= 1'b0;
        else
            enable <= 1'b1;
    end
endmodule

module ClockGatingUnit(
    input clk,
    input enable,
    output gated_clk
);
    // 组合逻辑部分
    assign gated_clk = clk & enable;
endmodule