//SystemVerilog
// Top-level Reset Synchronizer Module
module ResetSynchronizer (
    input  wire clk,
    input  wire rst_n,
    output wire rst_sync
);
    wire rst_sync_stage1;

    // First Stage: Reset Flip-Flop
    ResetSyncStage #(
        .INIT_VALUE(1'b0)
    ) u_stage1 (
        .clk    (clk),
        .rst_n  (rst_n),
        .d      (1'b1),
        .q      (rst_sync_stage1)
    );

    // Second Stage: Reset Flip-Flop
    ResetSyncStage #(
        .INIT_VALUE(1'b0)
    ) u_stage2 (
        .clk    (clk),
        .rst_n  (rst_n),
        .d      (rst_sync_stage1),
        .q      (rst_sync)
    );
endmodule

//-----------------------------------------------------------------------------
// Module: ResetSyncStage
// Description: Single-stage reset synchronizer flip-flop with async reset.
// Parameters:
//   - INIT_VALUE: Initial value after reset
//-----------------------------------------------------------------------------
module ResetSyncStage #(
    parameter INIT_VALUE = 1'b0
)(
    input  wire clk,
    input  wire rst_n,
    input  wire d,
    output reg  q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= INIT_VALUE;
        else
            q <= d;
    end
endmodule