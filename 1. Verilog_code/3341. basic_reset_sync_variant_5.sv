//SystemVerilog
module basic_reset_sync (
    input  wire clk,
    input  wire async_reset_n,
    output wire sync_reset_n
);
    // Pipeline stage 1: first synchronizer flop
    reg meta_flop_stage1;
    // Pipeline stage 2: second synchronizer flop
    reg meta_flop_stage2;
    // Pipeline stage 3: output register
    reg sync_reset_n_stage3;

    // Valid signal pipeline
    reg valid_stage1, valid_stage2, valid_stage3;

    // Flush logic for async reset
    wire flush = ~async_reset_n;

    // Stage 1: capture async reset
    always @(posedge clk or negedge async_reset_n) begin
        if (!async_reset_n) begin
            meta_flop_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            meta_flop_stage1 <= 1'b1;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: pipeline register for synchronizer
    always @(posedge clk or negedge async_reset_n) begin
        if (!async_reset_n) begin
            meta_flop_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            meta_flop_stage2 <= meta_flop_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: output register for further robustness
    always @(posedge clk or negedge async_reset_n) begin
        if (!async_reset_n) begin
            sync_reset_n_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            sync_reset_n_stage3 <= meta_flop_stage2;
            valid_stage3 <= valid_stage2;
        end
    end

    assign sync_reset_n = sync_reset_n_stage3 & valid_stage3;

endmodule