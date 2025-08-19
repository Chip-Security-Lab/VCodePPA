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
    output reg pred_valid
);

    // Pipeline registers
    reg [DW-1:0] pred_buffer [0:PRED_SIZE-1];
    reg [2:0] pred_index_stage1, pred_index_stage2;
    reg [DW-1:0] current_ctx_stage1, current_ctx_stage2;
    reg branch_taken_stage1, branch_taken_stage2;
    reg valid_stage1, valid_stage2;

    // Stage 1: Index calculation and buffer write
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pred_index_stage1 <= 0;
            current_ctx_stage1 <= 0;
            branch_taken_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            pred_index_stage1 <= (branch_taken) ? 0 : 
                                (pred_index_stage2 < PRED_SIZE-1) ? pred_index_stage2 + 1 : 0;
            current_ctx_stage1 <= current_ctx;
            branch_taken_stage1 <= branch_taken;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: Buffer read and context prediction
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pred_index_stage2 <= 0;
            current_ctx_stage2 <= 0;
            branch_taken_stage2 <= 0;
            valid_stage2 <= 0;
            pred_ctx <= 0;
            pred_valid <= 0;
        end else begin
            pred_index_stage2 <= pred_index_stage1;
            current_ctx_stage2 <= current_ctx_stage1;
            branch_taken_stage2 <= branch_taken_stage1;
            valid_stage2 <= valid_stage1;
            
            if (valid_stage1) begin
                pred_ctx <= pred_buffer[pred_index_stage1];
                pred_valid <= 1'b1;
            end else begin
                pred_valid <= 1'b0;
            end
        end
    end

    // Buffer write (combinational)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (integer i = 0; i < PRED_SIZE; i = i + 1) begin
                pred_buffer[i] <= 0;
            end
        end else if (valid_stage2) begin
            pred_buffer[pred_index_stage2] <= current_ctx_stage2;
        end
    end

endmodule