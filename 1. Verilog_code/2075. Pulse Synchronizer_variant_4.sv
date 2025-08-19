//SystemVerilog
module pulse_sync (
    input wire src_clk,
    input wire dst_clk,
    input wire rst_n,
    input wire pulse_in,
    output wire pulse_out
);

    // Source domain pipeline registers
    reg toggle_src_stage1;
    reg toggle_src_stage2;
    reg toggle_src_stage3;
    reg toggle_src_stage4;

    // Destination domain pipeline registers
    reg [2:0] sync_dst_stage1;
    reg [2:0] sync_dst_stage2;
    reg [2:0] sync_dst_stage3;
    reg [2:0] sync_dst_stage4;
    reg [2:0] sync_dst_stage5;
    reg [2:0] sync_dst_stage6;
    reg [2:0] sync_dst_stage7;

    // Source domain pipelining: deeper pipeline for toggle logic
    always @(posedge src_clk or negedge rst_n) begin
        if (!rst_n) begin
            toggle_src_stage1 <= 1'b0;
            toggle_src_stage2 <= 1'b0;
            toggle_src_stage3 <= 1'b0;
            toggle_src_stage4 <= 1'b0;
        end else begin
            // Stage 1: pulse_in controls toggling
            toggle_src_stage1 <= pulse_in ? ~toggle_src_stage4 : toggle_src_stage4;
            // Stage 2-4: pipeline for retiming
            toggle_src_stage2 <= toggle_src_stage1;
            toggle_src_stage3 <= toggle_src_stage2;
            toggle_src_stage4 <= toggle_src_stage3;
        end
    end

    // Destination domain synchronizer (deeper pipeline)
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_dst_stage1 <= 3'b0;
            sync_dst_stage2 <= 3'b0;
            sync_dst_stage3 <= 3'b0;
            sync_dst_stage4 <= 3'b0;
            sync_dst_stage5 <= 3'b0;
            sync_dst_stage6 <= 3'b0;
            sync_dst_stage7 <= 3'b0;
        end else begin
            // Stage 1: sample toggle_src_stage4 (from source domain, after pipeline)
            sync_dst_stage1 <= {sync_dst_stage1[1:0], toggle_src_stage4};
            // Stage 2-7: retiming and fanout buffering
            sync_dst_stage2 <= sync_dst_stage1;
            sync_dst_stage3 <= sync_dst_stage2;
            sync_dst_stage4 <= sync_dst_stage3;
            sync_dst_stage5 <= sync_dst_stage4;
            sync_dst_stage6 <= sync_dst_stage5;
            sync_dst_stage7 <= sync_dst_stage6;
        end
    end

    // Edge detector for output pulse using the last two pipeline stages
    assign pulse_out = sync_dst_stage7[2] ^ sync_dst_stage7[1];

endmodule