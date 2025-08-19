//SystemVerilog
`timescale 1ns / 1ps
`default_nettype none

module multi_output_rst_sync #(
    parameter STAGES = 3
) (
    input  wire clock,
    input  wire reset_in_n,
    output wire reset_out_n_stage1,
    output wire reset_out_n_stage2,
    output wire reset_out_n_stage3
);
    // 前向重定时优化：将寄存器移动到信号通路中更合理的位置
    (* ASYNC_REG = "TRUE" *) reg [STAGES:0] sync_pipeline = {(STAGES+1){1'b0}};
    
    // 优化后的单阶段寄存同步逻辑
    always @(posedge clock or negedge reset_in_n) begin
        if (!reset_in_n) begin
            sync_pipeline <= {(STAGES+1){1'b0}};
        end else begin
            sync_pipeline <= {sync_pipeline[STAGES-1:0], 1'b1};
        end
    end
    
    // 通过优化后的信号路径连接输出
    assign reset_out_n_stage1 = sync_pipeline[1];
    assign reset_out_n_stage2 = sync_pipeline[2];
    assign reset_out_n_stage3 = sync_pipeline[3];

endmodule

`default_nettype wire