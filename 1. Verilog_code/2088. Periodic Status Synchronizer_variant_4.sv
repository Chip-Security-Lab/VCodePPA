//SystemVerilog
module periodic_status_sync_pipeline #(
    parameter STATUS_WIDTH = 16,
    parameter PERIOD = 4
)(
    input  wire                   src_clk,
    input  wire                   dst_clk,
    input  wire                   reset,
    input  wire [STATUS_WIDTH-1:0] status_src,
    output reg  [STATUS_WIDTH-1:0] status_dst
);

    // Source domain: Stage 1 - Periodic sampling (remove register, move after logic)
    reg [$clog2(PERIOD)-1:0] period_counter_stage1;
    reg                      toggle_src_stage1;
    reg                      valid_stage1;

    always @(posedge src_clk or posedge reset) begin
        if (reset) begin
            period_counter_stage1   <= 0;
            toggle_src_stage1       <= 1'b0;
            valid_stage1            <= 1'b0;
        end else begin
            if (period_counter_stage1 == PERIOD-1) begin
                period_counter_stage1   <= 0;
                toggle_src_stage1       <= ~toggle_src_stage1;
                valid_stage1            <= 1'b1;
            end else begin
                period_counter_stage1   <= period_counter_stage1 + 1'b1;
                valid_stage1            <= 1'b0;
            end
        end
    end

    // Source domain: Stage 2 - Pipeline register for sampled data and toggle (move status_capture register here)
    reg [STATUS_WIDTH-1:0]   status_capture_stage2;
    reg                      toggle_src_stage2;
    reg                      valid_stage2;

    always @(posedge src_clk or posedge reset) begin
        if (reset) begin
            status_capture_stage2 <= {STATUS_WIDTH{1'b0}};
            toggle_src_stage2     <= 1'b0;
            valid_stage2          <= 1'b0;
        end else begin
            if (valid_stage1) begin
                status_capture_stage2 <= status_src; // move sample point here
                toggle_src_stage2     <= toggle_src_stage1;
                valid_stage2          <= 1'b1;
            end else begin
                valid_stage2          <= 1'b0;
            end
        end
    end

    // CDC pipeline: Double FF synchronizer for toggle_src
    reg toggle_src_sync_stage1_dstclk;
    reg toggle_src_sync_stage2_dstclk;
    reg toggle_src_sync_stage3_dstclk;

    always @(posedge dst_clk or posedge reset) begin
        if (reset) begin
            toggle_src_sync_stage1_dstclk <= 1'b0;
            toggle_src_sync_stage2_dstclk <= 1'b0;
            toggle_src_sync_stage3_dstclk <= 1'b0;
        end else begin
            toggle_src_sync_stage1_dstclk <= toggle_src_stage2;
            toggle_src_sync_stage2_dstclk <= toggle_src_sync_stage1_dstclk;
            toggle_src_sync_stage3_dstclk <= toggle_src_sync_stage2_dstclk;
        end
    end

    // CDC pipeline: status_capture bus synchronizer (two-stage pipeline)
    reg [STATUS_WIDTH-1:0] status_capture_sync_stage1_dstclk;
    reg [STATUS_WIDTH-1:0] status_capture_sync_stage2_dstclk;

    always @(posedge dst_clk or posedge reset) begin
        if (reset) begin
            status_capture_sync_stage1_dstclk <= {STATUS_WIDTH{1'b0}};
            status_capture_sync_stage2_dstclk <= {STATUS_WIDTH{1'b0}};
        end else begin
            status_capture_sync_stage1_dstclk <= status_capture_stage2;
            status_capture_sync_stage2_dstclk <= status_capture_sync_stage1_dstclk;
        end
    end

    // Destination domain: Stage 1 - Detect toggle, update status
    reg toggle_src_sync_stage2_dstclk_d;
    reg valid_dst_stage1;
    always @(posedge dst_clk or posedge reset) begin
        if (reset) begin
            status_dst                    <= {STATUS_WIDTH{1'b0}};
            toggle_src_sync_stage2_dstclk_d <= 1'b0;
            valid_dst_stage1              <= 1'b0;
        end else begin
            toggle_src_sync_stage2_dstclk_d <= toggle_src_sync_stage2_dstclk;
            if (toggle_src_sync_stage2_dstclk != toggle_src_sync_stage2_dstclk_d) begin
                status_dst       <= status_capture_sync_stage2_dstclk;
                valid_dst_stage1 <= 1'b1;
            end else begin
                valid_dst_stage1 <= 1'b0;
            end
        end
    end

endmodule