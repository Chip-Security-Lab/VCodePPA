//SystemVerilog
module pulse_sync (
    input wire src_clk,
    input wire dst_clk,
    input wire rst_n,
    input wire pulse_in,
    output wire pulse_out
);

    // Stage 1: Source domain pulse toggler
    reg toggle_src_stage1;
    reg valid_src_stage1;

    always @(posedge src_clk or negedge rst_n) begin
        if (!rst_n) begin
            toggle_src_stage1 <= 1'b0;
            valid_src_stage1 <= 1'b0;
        end else begin
            if (pulse_in) begin
                toggle_src_stage1 <= ~toggle_src_stage1;
                valid_src_stage1 <= 1'b1;
            end else begin
                toggle_src_stage1 <= toggle_src_stage1;
                valid_src_stage1 <= 1'b0;
            end
        end
    end

    // Stage 2: CDC synchronizer - 3-stage shift register in destination domain
    reg sync_stage1;
    reg sync_stage2;
    reg sync_stage3;
    reg valid_dst_stage1;
    reg valid_dst_stage2;
    reg valid_dst_stage3;

    // CDC: synchronize toggle_src_stage1 into dst_clk domain with valid signal
    reg toggle_src_meta;
    reg valid_src_meta;

    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            toggle_src_meta    <= 1'b0;
            sync_stage1        <= 1'b0;
            sync_stage2        <= 1'b0;
            sync_stage3        <= 1'b0;
            valid_src_meta     <= 1'b0;
            valid_dst_stage1   <= 1'b0;
            valid_dst_stage2   <= 1'b0;
            valid_dst_stage3   <= 1'b0;
        end else begin
            // Stage 1: metastability filter for toggle and valid
            toggle_src_meta   <= toggle_src_stage1;
            valid_src_meta    <= valid_src_stage1;

            // Stage 2: first sync register stage
            sync_stage1       <= toggle_src_meta;
            valid_dst_stage1  <= valid_src_meta;

            // Stage 3: second sync register stage
            sync_stage2       <= sync_stage1;
            valid_dst_stage2  <= valid_dst_stage1;

            // Stage 4: third sync register stage
            sync_stage3       <= sync_stage2;
            valid_dst_stage3  <= valid_dst_stage2;
        end
    end

    // Stage 5: Edge detection and valid propagation
    reg pulse_out_stage1;
    reg valid_pulse_stage1;

    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            pulse_out_stage1   <= 1'b0;
            valid_pulse_stage1 <= 1'b0;
        end else begin
            pulse_out_stage1   <= sync_stage3 ^ sync_stage2;
            valid_pulse_stage1 <= valid_dst_stage3;
        end
    end

    assign pulse_out = valid_pulse_stage1 & pulse_out_stage1;

endmodule