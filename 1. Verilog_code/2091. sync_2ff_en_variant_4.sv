//SystemVerilog
module sync_2ff_en_pipeline #(parameter DW=8) (
    input  wire              src_clk,
    input  wire              dst_clk,
    input  wire              rst_n,
    input  wire              en,
    input  wire [DW-1:0]     async_in,
    output reg  [DW-1:0]     synced_out
);

    // Stage 1: Fanout buffer for async_in[0]
    reg                      b0_buf1, b0_buf2;

    // Stage 1: Fanout buffer for en
    reg                      en_buf1, en_buf2;

    // Stage 2: First sync register after combination logic
    reg [DW-1:0]             sync_ff_stage1;
    reg                      valid_stage1;
    reg                      valid_stage1_buf1, valid_stage1_buf2;

    // Stage 3: Second sync register
    reg [DW-1:0]             sync_ff_stage2;
    reg                      valid_stage2;
    reg                      valid_stage2_buf1, valid_stage2_buf2;

    // Stage 4: Output register
    reg [DW-1:0]             synced_out_stage3;
    reg                      valid_stage3;
    reg                      valid_stage3_buf1, valid_stage3_buf2;

    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            // Stage 1 fanout buffers
            b0_buf1             <= 1'b0;
            b0_buf2             <= 1'b0;
            en_buf1             <= 1'b0;
            en_buf2             <= 1'b0;
            // Stage 2 registers and buffers
            sync_ff_stage1      <= {DW{1'b0}};
            valid_stage1        <= 1'b0;
            valid_stage1_buf1   <= 1'b0;
            valid_stage1_buf2   <= 1'b0;
            // Stage 3 registers and buffers
            sync_ff_stage2      <= {DW{1'b0}};
            valid_stage2        <= 1'b0;
            valid_stage2_buf1   <= 1'b0;
            valid_stage2_buf2   <= 1'b0;
            // Stage 4 registers and buffers
            synced_out_stage3   <= {DW{1'b0}};
            valid_stage3        <= 1'b0;
            valid_stage3_buf1   <= 1'b0;
            valid_stage3_buf2   <= 1'b0;
            synced_out          <= {DW{1'b0}};
        end else begin
            // Stage 1: Buffer input signals for fanout reduction
            b0_buf1 <= async_in[0];
            b0_buf2 <= async_in[0];
            en_buf1 <= en;
            en_buf2 <= en;

            // Stage 2: Move the first register after en gating (forward register retiming)
            if (en_buf1) begin
                sync_ff_stage1 <= async_in;
                valid_stage1   <= 1'b1;
            end else begin
                valid_stage1   <= 1'b0;
            end
            valid_stage1_buf1 <= valid_stage1;
            valid_stage1_buf2 <= valid_stage1;

            // Stage 3: Second sync register
            if (valid_stage1_buf1) begin
                sync_ff_stage2 <= sync_ff_stage1;
                valid_stage2   <= 1'b1;
            end else begin
                valid_stage2   <= 1'b0;
            end
            valid_stage2_buf1 <= valid_stage2;
            valid_stage2_buf2 <= valid_stage2;

            // Stage 4: Output register
            if (valid_stage2_buf1) begin
                synced_out_stage3 <= sync_ff_stage2;
                valid_stage3      <= 1'b1;
            end else begin
                valid_stage3      <= 1'b0;
            end
            valid_stage3_buf1 <= valid_stage3;
            valid_stage3_buf2 <= valid_stage3;

            // Output assignment
            if (valid_stage3_buf1) begin
                synced_out <= synced_out_stage3;
            end
        end
    end

endmodule