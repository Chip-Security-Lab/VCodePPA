//SystemVerilog
module basic_reset_sync_pipeline (
    input  wire clk,
    input  wire async_reset_n,
    output reg  sync_reset_n
);
    reg stage1_ff, stage2_ff;

    always @(posedge clk or negedge async_reset_n) begin
        stage1_ff    <= (!async_reset_n) ? 1'b0 : 1'b1;
        stage2_ff    <= (!async_reset_n) ? 1'b0 : stage1_ff;
        sync_reset_n <= (!async_reset_n) ? 1'b0 : stage2_ff;
    end
endmodule