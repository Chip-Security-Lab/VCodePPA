//SystemVerilog
module pulse_sync (
    input wire src_clk,
    input wire dst_clk,
    input wire rst_n,
    input wire pulse_in,
    output wire pulse_out
);

    // Stage 1: Source domain toggle logic
    reg toggle_src_stage1;
    reg toggle_src_stage2;
    reg valid_src_stage1;
    reg valid_src_stage2;

    // Stage 2: Destination domain synchronizer (3-stage)
    reg [2:0] sync_dst_stage1;
    reg [2:0] sync_dst_stage2;
    reg valid_dst_stage1;
    reg valid_dst_stage2;

    // Stage 3: Output pulse generation
    reg pulse_out_stage1;
    reg pulse_out_stage2;
    reg valid_out_stage1;
    reg valid_out_stage2;

    // Pipeline register for source domain toggle logic
    wire toggle_src_next_stage1;
    assign toggle_src_next_stage1 = pulse_in ^ toggle_src_stage1;

    // Source domain pipeline
    always @(posedge src_clk or negedge rst_n) begin
        if (!rst_n) begin
            toggle_src_stage1 <= 1'b0;
            valid_src_stage1  <= 1'b0;
        end else begin
            toggle_src_stage1 <= toggle_src_next_stage1 ? ~toggle_src_stage1 : toggle_src_stage1;
            valid_src_stage1  <= 1'b1;
        end
    end

    // Pipeline register for toggle_src_stage2 (for crossing to dst_clk domain)
    always @(posedge src_clk or negedge rst_n) begin
        if (!rst_n) begin
            toggle_src_stage2 <= 1'b0;
            valid_src_stage2  <= 1'b0;
        end else begin
            toggle_src_stage2 <= toggle_src_stage1;
            valid_src_stage2  <= valid_src_stage1;
        end
    end

    // CDC: Synchronize toggle_src_stage2 to destination domain (3-stage synchronizer)
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_dst_stage1 <= 3'b0;
            valid_dst_stage1 <= 1'b0;
        end else begin
            sync_dst_stage1 <= {sync_dst_stage1[1:0], toggle_src_stage2};
            valid_dst_stage1 <= valid_src_stage2;
        end
    end

    // Pipeline register for sync_dst_stage2
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_dst_stage2 <= 3'b0;
            valid_dst_stage2 <= 1'b0;
        end else begin
            sync_dst_stage2 <= sync_dst_stage1;
            valid_dst_stage2 <= valid_dst_stage1;
        end
    end

    // Output pulse generation pipeline stage 1
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            pulse_out_stage1 <= 1'b0;
            valid_out_stage1 <= 1'b0;
        end else begin
            pulse_out_stage1 <= sync_dst_stage2[2] ^ sync_dst_stage2[1];
            valid_out_stage1 <= valid_dst_stage2;
        end
    end

    // Output pulse generation pipeline stage 2 (final output)
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            pulse_out_stage2 <= 1'b0;
            valid_out_stage2 <= 1'b0;
        end else begin
            pulse_out_stage2 <= pulse_out_stage1;
            valid_out_stage2 <= valid_out_stage1;
        end
    end

    // Assign final output
    assign pulse_out = pulse_out_stage2 & valid_out_stage2;

endmodule