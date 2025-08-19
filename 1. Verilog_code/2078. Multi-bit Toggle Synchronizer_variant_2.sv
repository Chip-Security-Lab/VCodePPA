//SystemVerilog
module multibit_toggle_sync_pipeline #(parameter WIDTH = 4) (
    input wire src_clk,
    input wire dst_clk,
    input wire reset,
    input wire [WIDTH-1:0] data_src,
    input wire update,
    output reg [WIDTH-1:0] data_dst
);

    // Stage 1: Register input data and update in source clock domain
    reg [WIDTH-1:0] data_src_stage1;
    reg update_stage1;
    reg toggle_stage1;
    reg valid_stage1;

    wire update_edge;
    assign update_edge = update & ~update_stage1;

    always @(posedge src_clk) begin
        if (reset) begin
            data_src_stage1 <= {WIDTH{1'b0}};
            update_stage1   <= 1'b0;
            toggle_stage1   <= 1'b0;
            valid_stage1    <= 1'b0;
        end else begin
            data_src_stage1 <= data_src;
            update_stage1   <= update;
            toggle_stage1   <= update ? ~toggle_stage1 : toggle_stage1;
            valid_stage1    <= update;
        end
    end

    // Stage 2: Pipeline register for toggle and data to align with synchronizer
    reg toggle_stage2;
    reg [WIDTH-1:0] data_src_stage2;
    reg valid_stage2;

    always @(posedge src_clk) begin
        if (reset) begin
            toggle_stage2    <= 1'b0;
            data_src_stage2  <= {WIDTH{1'b0}};
            valid_stage2     <= 1'b0;
        end else begin
            toggle_stage2    <= toggle_stage1;
            data_src_stage2  <= data_src_stage1;
            valid_stage2     <= valid_stage1;
        end
    end

    // Stage 3: Synchronize toggle signal to destination clock domain (3-stage synchronizer)
    reg toggle_sync_stage1, toggle_sync_stage2, toggle_sync_stage3;
    always @(posedge dst_clk) begin
        if (reset) begin
            toggle_sync_stage1 <= 1'b0;
            toggle_sync_stage2 <= 1'b0;
            toggle_sync_stage3 <= 1'b0;
        end else begin
            toggle_sync_stage1 <= toggle_stage2;
            toggle_sync_stage2 <= toggle_sync_stage1;
            toggle_sync_stage3 <= toggle_sync_stage2;
        end
    end

    // Pipeline for data and valid across dst_clk domain
    reg [WIDTH-1:0] data_src_stage2_dst;
    reg valid_stage2_dst;
    reg [WIDTH-1:0] data_src_stage2_dstclk;
    reg valid_stage2_dstclk;

    always @(posedge dst_clk) begin
        if (reset) begin
            data_src_stage2_dst   <= {WIDTH{1'b0}};
            valid_stage2_dst      <= 1'b0;
            data_src_stage2_dstclk<= {WIDTH{1'b0}};
            valid_stage2_dstclk   <= 1'b0;
        end else begin
            data_src_stage2_dst   <= data_src_stage2;
            valid_stage2_dst      <= valid_stage2;
            data_src_stage2_dstclk<= data_src_stage2_dst;
            valid_stage2_dstclk   <= valid_stage2_dst;
        end
    end

    // Balanced detection and pipeline
    reg [WIDTH-1:0] data_captured_stage1;
    reg [WIDTH-1:0] data_captured_stage2;
    reg [1:0] valid_pipeline;

    wire toggle_edge_detected;
    assign toggle_edge_detected = toggle_sync_stage3 ^ toggle_sync_stage2;

    always @(posedge dst_clk) begin
        if (reset) begin
            data_captured_stage1 <= {WIDTH{1'b0}};
            data_captured_stage2 <= {WIDTH{1'b0}};
            valid_pipeline       <= 2'b0;
        end else begin
            // Balanced: Separate data/valid pipeline from edge detection
            if (toggle_edge_detected) begin
                data_captured_stage1 <= data_src_stage2_dstclk;
                valid_pipeline[0]    <= valid_stage2_dstclk;
            end else begin
                valid_pipeline[0]    <= 1'b0;
            end
            data_captured_stage2 <= data_captured_stage1;
            valid_pipeline[1]    <= valid_pipeline[0];
        end
    end

    // Output stage
    always @(posedge dst_clk) begin
        if (reset) begin
            data_dst <= {WIDTH{1'b0}};
        end else if (valid_pipeline[1]) begin
            data_dst <= data_captured_stage2;
        end
    end

endmodule