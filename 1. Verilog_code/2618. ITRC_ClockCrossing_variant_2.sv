//SystemVerilog
module ITRC_ClockCrossing #(
    parameter SYNC_STAGES = 2
)(
    input  src_clk,
    input  dst_clk,
    input  async_int,
    output sync_int
);

    // 预计算常量
    localparam LAST_STAGE = SYNC_STAGES - 1;
    localparam PREV_STAGES = SYNC_STAGES - 1;
    localparam MID_STAGE = SYNC_STAGES / 2;

    // 时序逻辑部分 - 使用更平衡的移位结构
    reg [SYNC_STAGES-1:0] sync_chain;
    reg [SYNC_STAGES-1:0] sync_chain_stage1;
    reg [SYNC_STAGES-1:0] sync_chain_stage2;

    // 第一级流水线
    always @(posedge dst_clk) begin
        sync_chain_stage1 <= {sync_chain_stage1[PREV_STAGES-1:0], async_int};
    end

    // 第二级流水线
    always @(posedge dst_clk) begin
        sync_chain_stage2 <= sync_chain_stage1;
    end

    // 第三级流水线
    always @(posedge dst_clk) begin
        sync_chain <= sync_chain_stage2;
    end

    // 直接输出最后一级触发器
    assign sync_int = sync_chain[LAST_STAGE];

endmodule