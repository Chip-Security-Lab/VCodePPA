//SystemVerilog
module dual_clock_recovery (
    // Source domain
    input wire src_clk,
    input wire src_rst_n,
    input wire [7:0] src_data,
    input wire src_valid,
    // Destination domain
    input wire dst_clk,
    input wire dst_rst_n,
    output reg [7:0] dst_data,
    output reg dst_valid
);
    // Source domain registers - Multi-stage pipeline
    reg [7:0] src_data_stage1;
    reg [7:0] src_data_stage2;
    reg src_valid_stage1;
    reg src_valid_stage2;
    reg src_toggle;
    
    // Destination domain registers - Enhanced synchronizer
    reg [3:0] dst_sync;  // Increased synchronizer depth
    reg dst_edge_detected_stage1;
    reg dst_edge_detected_stage2;
    reg [7:0] dst_data_capture_stage1;
    reg [7:0] dst_data_capture_stage2;
    reg dst_valid_stage1;
    
    // Source domain pipeline - Stage 1
    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            src_data_stage1 <= 8'h0;
            src_valid_stage1 <= 1'b0;
        end else begin
            src_data_stage1 <= src_data;
            src_valid_stage1 <= src_valid;
        end
    end
    
    // Source domain pipeline - Stage 2
    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            src_data_stage2 <= 8'h0;
            src_valid_stage2 <= 1'b0;
            src_toggle <= 1'b0;
        end else begin
            src_data_stage2 <= src_data_stage1;
            src_valid_stage2 <= src_valid_stage1;
            
            if (src_valid_stage2) begin
                src_toggle <= ~src_toggle;
            end
        end
    end
    
    // Destination domain synchronizer - Multi-stage
    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            dst_sync <= 4'b0;
        end else begin
            dst_sync <= {dst_sync[2:0], src_toggle};
        end
    end
    
    // Edge detection pipeline - Stage 1
    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            dst_edge_detected_stage1 <= 1'b0;
            dst_data_capture_stage1 <= 8'h0;
        end else begin
            dst_edge_detected_stage1 <= (dst_sync[3] != dst_sync[2]);
            dst_data_capture_stage1 <= src_data_stage2;
        end
    end
    
    // Edge detection pipeline - Stage 2
    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            dst_edge_detected_stage2 <= 1'b0;
            dst_data_capture_stage2 <= 8'h0;
            dst_valid_stage1 <= 1'b0;
        end else begin
            dst_edge_detected_stage2 <= dst_edge_detected_stage1;
            dst_data_capture_stage2 <= dst_data_capture_stage1;
            dst_valid_stage1 <= dst_edge_detected_stage2;
        end
    end
    
    // Final output stage
    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            dst_data <= 8'h0;
            dst_valid <= 1'b0;
        end else begin
            dst_data <= dst_valid_stage1 ? dst_data_capture_stage2 : dst_data;
            dst_valid <= dst_valid_stage1;
        end
    end
endmodule