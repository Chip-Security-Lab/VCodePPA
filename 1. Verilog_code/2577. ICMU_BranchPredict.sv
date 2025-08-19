module ICMU_BranchPredict #(
    parameter DW = 64,
    parameter PRED_SIZE = 8
)(
    input clk,
    input branch_taken,
    input [DW-1:0] current_ctx,
    output reg [DW-1:0] pred_ctx
);
    reg [DW-1:0] pred_buffer [0:PRED_SIZE-1];
    reg [2:0] pred_index;

    always @(posedge clk) begin
        if (branch_taken) begin
            pred_index <= 0;
            pred_ctx <= pred_buffer[0];
        end else begin
            pred_index <= (pred_index < PRED_SIZE-1) ? pred_index + 1 : 0;
            pred_ctx <= pred_buffer[pred_index];
        end
        pred_buffer[pred_index] <= current_ctx;
    end
endmodule
