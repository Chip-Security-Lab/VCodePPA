//SystemVerilog
module clock_enable_sync (
    input  wire fast_clk,
    input  wire slow_clk,
    input  wire rst_n,
    input  wire enable_src,
    output reg  enable_dst
);

    // Stage 1: Capture on source domain
    reg enable_src_ff_stage1;
    reg valid_stage1;

    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_src_ff_stage1 <= 1'b0;
            valid_stage1         <= 1'b0;
        end else begin
            enable_src_ff_stage1 <= enable_src;
            valid_stage1         <= 1'b1;
        end
    end

    // Stage 2: Synchronize to destination domain (first stage of CDC)
    reg enable_meta_stage2, enable_meta_stage2_d;
    reg valid_stage2, valid_stage2_d;

    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_meta_stage2   <= 1'b0;
            enable_meta_stage2_d <= 1'b0;
            valid_stage2         <= 1'b0;
            valid_stage2_d       <= 1'b0;
        end else begin
            enable_meta_stage2   <= enable_src_ff_stage1;
            enable_meta_stage2_d <= enable_meta_stage2;
            valid_stage2         <= valid_stage1;
            valid_stage2_d       <= valid_stage2;
        end
    end

    // Balanced output logic with pre-evaluated valid and data
    wire enable_sync_ready;
    assign enable_sync_ready = valid_stage2_d & enable_meta_stage2_d;

    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_dst <= 1'b0;
        end else begin
            // Balanced path for output register
            enable_dst <= enable_sync_ready | (enable_dst & ~valid_stage2_d);
        end
    end

endmodule