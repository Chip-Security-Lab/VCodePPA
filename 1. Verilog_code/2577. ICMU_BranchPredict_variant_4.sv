//SystemVerilog
module ICMU_BranchPredict #(
    parameter DW = 64,
    parameter PRED_SIZE = 8
)(
    input clk,
    input rst_n,
    input branch_taken,
    input [DW-1:0] current_ctx,
    output reg [DW-1:0] pred_ctx,
    output reg valid
);

    reg [DW-1:0] current_ctx_stage1;
    reg branch_taken_stage1;
    reg [2:0] pred_index_stage1;
    reg valid_stage1;
    reg [DW-1:0] pred_buffer_stage2 [0:PRED_SIZE-1];
    reg [2:0] pred_index_stage2;
    reg valid_stage2;
    reg [DW-1:0] pred_ctx_stage3;
    reg valid_stage3;

    wire [2:0] next_index = (branch_taken) ? 3'b0 : 
                           ((pred_index_stage2 < PRED_SIZE-1) ? pred_index_stage2 + 1'b1 : 3'b0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_ctx_stage1 <= {DW{1'b0}};
            branch_taken_stage1 <= 1'b0;
            pred_index_stage1 <= 3'b0;
            valid_stage1 <= 1'b0;
        end else begin
            current_ctx_stage1 <= current_ctx;
            branch_taken_stage1 <= branch_taken;
            pred_index_stage1 <= next_index;
            valid_stage1 <= 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < PRED_SIZE; i = i + 1) begin
                pred_buffer_stage2[i] <= {DW{1'b0}};
            end
            pred_index_stage2 <= 3'b0;
            valid_stage2 <= 1'b0;
        end else begin
            pred_buffer_stage2[pred_index_stage1] <= current_ctx_stage1;
            pred_index_stage2 <= pred_index_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pred_ctx_stage3 <= {DW{1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            pred_ctx_stage3 <= pred_buffer_stage2[pred_index_stage2];
            valid_stage3 <= valid_stage2;
        end
    end

    assign pred_ctx = pred_ctx_stage3;
    assign valid = valid_stage3;

endmodule