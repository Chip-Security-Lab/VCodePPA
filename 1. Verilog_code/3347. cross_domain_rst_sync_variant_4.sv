//SystemVerilog
module cross_domain_rst_sync_pipeline (
    input  wire clk_src,
    input  wire clk_dst,
    input  wire async_rst_n,
    output wire sync_rst_n_dst
);
    // Stage 1: Source clock domain synchronization pipeline
    reg rst_src_meta_stage1, rst_src_meta_stage2, rst_src_meta_stage3;
    reg valid_src_stage1, valid_src_stage2, valid_src_stage3;
    reg flush_src_pipeline;

    // Stage 2: Destination clock domain synchronization pipeline
    reg rst_dst_meta_stage1, rst_dst_meta_stage2, rst_dst_meta_stage3;
    reg valid_dst_stage1, valid_dst_stage2, valid_dst_stage3;
    reg flush_dst_pipeline;

    // Pipeline flush logic
    always @(posedge clk_src or negedge async_rst_n) begin
        if (!async_rst_n) begin
            flush_src_pipeline <= 1'b1;
        end else begin
            flush_src_pipeline <= 1'b0;
        end
    end

    always @(posedge clk_dst or negedge async_rst_n) begin
        if (!async_rst_n) begin
            flush_dst_pipeline <= 1'b1;
        end else begin
            flush_dst_pipeline <= 1'b0;
        end
    end

    // Source domain pipeline, add extra stage for pipelining
    always @(posedge clk_src or negedge async_rst_n) begin
        if (!async_rst_n) begin
            rst_src_meta_stage1 <= 1'b0;
            rst_src_meta_stage2 <= 1'b0;
            rst_src_meta_stage3 <= 1'b0;
            valid_src_stage1    <= 1'b0;
            valid_src_stage2    <= 1'b0;
            valid_src_stage3    <= 1'b0;
        end else if (flush_src_pipeline) begin
            rst_src_meta_stage1 <= 1'b1;
            rst_src_meta_stage2 <= 1'b1;
            rst_src_meta_stage3 <= 1'b1;
            valid_src_stage1    <= 1'b1;
            valid_src_stage2    <= 1'b1;
            valid_src_stage3    <= 1'b1;
        end else begin
            // Stage 1
            rst_src_meta_stage1 <= 1'b1;
            valid_src_stage1    <= 1'b1;
            // Stage 2
            rst_src_meta_stage2 <= rst_src_meta_stage1;
            valid_src_stage2    <= valid_src_stage1;
            // Stage 3 (pipelined)
            rst_src_meta_stage3 <= rst_src_meta_stage2;
            valid_src_stage3    <= valid_src_stage2;
        end
    end

    // Destination domain pipeline, add extra stage for pipelining
    always @(posedge clk_dst or negedge async_rst_n) begin
        if (!async_rst_n) begin
            rst_dst_meta_stage1 <= 1'b0;
            rst_dst_meta_stage2 <= 1'b0;
            rst_dst_meta_stage3 <= 1'b0;
            valid_dst_stage1    <= 1'b0;
            valid_dst_stage2    <= 1'b0;
            valid_dst_stage3    <= 1'b0;
        end else if (flush_dst_pipeline) begin
            rst_dst_meta_stage1 <= 1'b1;
            rst_dst_meta_stage2 <= 1'b1;
            rst_dst_meta_stage3 <= 1'b1;
            valid_dst_stage1    <= 1'b1;
            valid_dst_stage2    <= 1'b1;
            valid_dst_stage3    <= 1'b1;
        end else begin
            // Stage 1: Transfer from source to destination domain (using valid signal)
            rst_dst_meta_stage1 <= rst_src_meta_stage3;
            valid_dst_stage1    <= valid_src_stage3;
            // Stage 2
            rst_dst_meta_stage2 <= rst_dst_meta_stage1;
            valid_dst_stage2    <= valid_dst_stage1;
            // Stage 3 (pipelined)
            rst_dst_meta_stage3 <= rst_dst_meta_stage2;
            valid_dst_stage3    <= valid_dst_stage2;
        end
    end

    // Final output with pipelined registers to reduce logic depth
    reg sync_rst_n_dst_p1, sync_rst_n_dst_p2;

    always @(posedge clk_dst or negedge async_rst_n) begin
        if (!async_rst_n) begin
            sync_rst_n_dst_p1 <= 1'b0;
            sync_rst_n_dst_p2 <= 1'b0;
        end else begin
            sync_rst_n_dst_p1 <= rst_dst_meta_stage3 & valid_dst_stage3;
            sync_rst_n_dst_p2 <= sync_rst_n_dst_p1;
        end
    end

    assign sync_rst_n_dst = sync_rst_n_dst_p2;

endmodule