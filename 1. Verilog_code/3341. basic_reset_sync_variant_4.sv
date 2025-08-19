//SystemVerilog
module basic_reset_sync_pipeline (
    input  wire clk,
    input  wire async_reset_n,
    output reg  sync_reset_n
);

    // Pipeline registers for reset synchronizer
    reg meta_flop_stage1;
    reg meta_flop_stage2;
    reg meta_flop_stage3;
    reg meta_flop_stage4;

    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;
    reg valid_stage4;

    // Stage 1: First synchronizer flip-flop
    always @(posedge clk or negedge async_reset_n) begin
        if (!async_reset_n) begin
            meta_flop_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            meta_flop_stage1 <= 1'b1;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: Second synchronizer flip-flop and valid propagation
    always @(posedge clk or negedge async_reset_n) begin
        if (!async_reset_n) begin
            meta_flop_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            meta_flop_stage2 <= meta_flop_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Third synchronizer flip-flop and valid propagation
    always @(posedge clk or negedge async_reset_n) begin
        if (!async_reset_n) begin
            meta_flop_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            meta_flop_stage3 <= meta_flop_stage2;
            valid_stage3 <= valid_stage2;
        end
    end

    // Stage 4: Fourth synchronizer flip-flop and valid propagation
    always @(posedge clk or negedge async_reset_n) begin
        if (!async_reset_n) begin
            meta_flop_stage4 <= 1'b0;
            valid_stage4 <= 1'b0;
        end else begin
            meta_flop_stage4 <= meta_flop_stage3;
            valid_stage4 <= valid_stage3;
        end
    end

    // Output logic with valid control
    always @(posedge clk or negedge async_reset_n) begin
        if (!async_reset_n) begin
            sync_reset_n <= 1'b0;
        end else if (valid_stage4) begin
            sync_reset_n <= meta_flop_stage4;
        end
    end

endmodule