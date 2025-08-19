//SystemVerilog
module sync_2ff_en_pipeline #(
    parameter DW = 8
) (
    input              src_clk,
    input              dst_clk,
    input              rst_n,
    input              en,
    input  [DW-1:0]    async_in,
    output [DW-1:0]    synced_out,
    output             synced_out_valid
);

    // Stage 1 pipeline registers
    reg [DW-1:0] async_in_stage1;
    reg          valid_stage1;

    // Stage 2 pipeline registers
    reg [DW-1:0] async_in_stage2;
    reg          valid_stage2;

    // Stage 3 pipeline registers
    reg [DW-1:0] async_in_stage3;
    reg          valid_stage3;

    // Pipeline flush logic
    wire pipeline_flush = ~rst_n;

    // Stage 1: Capture async_in with en
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            async_in_stage1 <= {DW{1'b0}};
            valid_stage1    <= 1'b0;
        end else if (en) begin
            async_in_stage1 <= async_in;
            valid_stage1    <= 1'b1;
        end else begin
            async_in_stage1 <= async_in_stage1;
            valid_stage1    <= 1'b0;
        end
    end

    // Stage 2: First synchronizer flip-flop
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            async_in_stage2 <= {DW{1'b0}};
            valid_stage2    <= 1'b0;
        end else begin
            async_in_stage2 <= async_in_stage1;
            valid_stage2    <= valid_stage1;
        end
    end

    // Stage 3: Second synchronizer flip-flop
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            async_in_stage3 <= {DW{1'b0}};
            valid_stage3    <= 1'b0;
        end else begin
            async_in_stage3 <= async_in_stage2;
            valid_stage3    <= valid_stage2;
        end
    end

    assign synced_out = async_in_stage3;
    assign synced_out_valid = valid_stage3;

endmodule