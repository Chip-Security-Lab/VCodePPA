//SystemVerilog
module dual_clock_recovery_pipelined (
    input wire src_clk,
    input wire src_rst_n,
    input wire [7:0] src_data,
    input wire src_valid,
    input wire dst_clk,
    input wire dst_rst_n,
    output reg [7:0] dst_data,
    output reg dst_valid
);

    // Source domain pipeline registers
    reg [7:0] src_data_stage1;
    reg src_valid_stage1;
    reg src_toggle_stage1;
    
    reg [7:0] src_data_stage2;
    reg src_valid_stage2;
    reg src_toggle_stage2;
    
    // Destination domain pipeline registers
    reg [1:0] dst_sync_stage1;
    reg [1:0] dst_sync_stage2;
    reg dst_sync_prev_stage1;
    reg dst_sync_prev_stage2;
    reg [7:0] dst_data_stage1;
    reg [7:0] dst_data_stage2;
    reg toggle_edge_stage1;
    reg toggle_edge_stage2;
    
    // Source domain pipeline stage 1
    wire toggle_next = src_valid ? ~src_toggle_stage1 : src_toggle_stage1;
    
    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            src_data_stage1 <= 8'h0;
            src_valid_stage1 <= 1'b0;
            src_toggle_stage1 <= 1'b0;
        end else begin
            src_data_stage1 <= src_data;
            src_valid_stage1 <= src_valid;
            src_toggle_stage1 <= toggle_next;
        end
    end
    
    // Source domain pipeline stage 2
    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            src_data_stage2 <= 8'h0;
            src_valid_stage2 <= 1'b0;
            src_toggle_stage2 <= 1'b0;
        end else begin
            src_data_stage2 <= src_data_stage1;
            src_valid_stage2 <= src_valid_stage1;
            src_toggle_stage2 <= src_toggle_stage1;
        end
    end
    
    // Destination domain pipeline stage 1
    wire sync_edge_stage1 = dst_sync_stage1[1] ^ dst_sync_prev_stage1;
    
    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            dst_sync_stage1 <= 2'b0;
            dst_sync_prev_stage1 <= 1'b0;
            dst_data_stage1 <= 8'h0;
            toggle_edge_stage1 <= 1'b0;
        end else begin
            dst_sync_stage1 <= {dst_sync_stage1[0], src_toggle_stage2};
            dst_sync_prev_stage1 <= dst_sync_stage1[1];
            dst_data_stage1 <= src_data_stage2;
            toggle_edge_stage1 <= sync_edge_stage1;
        end
    end
    
    // Destination domain pipeline stage 2
    wire sync_edge_stage2 = dst_sync_stage2[1] ^ dst_sync_prev_stage2;
    
    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            dst_sync_stage2 <= 2'b0;
            dst_sync_prev_stage2 <= 1'b0;
            dst_data_stage2 <= 8'h0;
            toggle_edge_stage2 <= 1'b0;
            dst_data <= 8'h0;
            dst_valid <= 1'b0;
        end else begin
            dst_sync_stage2 <= dst_sync_stage1;
            dst_sync_prev_stage2 <= dst_sync_prev_stage1;
            dst_data_stage2 <= dst_data_stage1;
            toggle_edge_stage2 <= toggle_edge_stage1;
            dst_data <= toggle_edge_stage2 ? dst_data_stage2 : dst_data;
            dst_valid <= toggle_edge_stage2;
        end
    end

endmodule