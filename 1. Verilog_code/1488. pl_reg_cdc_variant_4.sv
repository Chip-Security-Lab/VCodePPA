//SystemVerilog - IEEE 1364-2005 Standard
module pl_reg_cdc #(parameter W=8) (
    input wire src_clk,          // Source clock domain
    input wire dst_clk,          // Destination clock domain
    input wire src_rst_n,        // Source domain active-low reset
    input wire dst_rst_n,        // Destination domain active-low reset
    input wire src_valid,        // Source data valid signal
    input wire [W-1:0] src_data, // Source data input
    output wire dst_valid,       // Destination data valid signal
    output wire [W-1:0] dst_data // Destination data output
);

    // Source domain registers - moved toggle generation before data registration
    reg src_toggle_reg;
    reg [W-1:0] src_data_reg;
    
    // Synchronization registers in destination domain
    reg [2:0] dst_sync_toggle; // 3-stage synchronizer for toggle bit
    
    // Destination domain registers
    reg [W-1:0] dst_data_reg;
    reg dst_valid_reg;
    reg dst_toggle_prev;

    // Source domain - toggle bit generation for CDC
    // Moved earlier in the pipeline to reduce input-to-register delay
    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            src_toggle_reg <= 1'b0;
        end else if (src_valid) begin
            src_toggle_reg <= ~src_toggle_reg; // Toggle on new valid data
        end
    end

    // Source domain - data registration
    // Moved after toggle generation to balance pipeline stages
    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            src_data_reg <= {W{1'b0}};
        end else if (src_valid) begin
            src_data_reg <= src_data;
        end
    end

    // First stage of synchronizer
    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            dst_sync_toggle[0] <= 1'b0;
        end else begin
            dst_sync_toggle[0] <= src_toggle_reg;
        end
    end

    // Second stage of synchronizer
    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            dst_sync_toggle[1] <= 1'b0;
        end else begin
            dst_sync_toggle[1] <= dst_sync_toggle[0];
        end
    end

    // Third stage of synchronizer
    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            dst_sync_toggle[2] <= 1'b0;
        end else begin
            dst_sync_toggle[2] <= dst_sync_toggle[1];
        end
    end

    // Destination domain - toggle detection and valid signal generation combined
    // Optimized to reduce logic between register stages
    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            dst_toggle_prev <= 1'b0;
            dst_valid_reg <= 1'b0;
        end else begin
            dst_toggle_prev <= dst_sync_toggle[2];
            dst_valid_reg <= (dst_sync_toggle[2] != dst_toggle_prev);
        end
    end

    // Destination domain - data capture
    // Forwarding the data capture logic to reduce critical path
    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            dst_data_reg <= {W{1'b0}};
        end else if (dst_sync_toggle[2] != dst_toggle_prev) begin
            dst_data_reg <= src_data_reg;
        end
    end

    // Output assignments
    assign dst_data = dst_data_reg;
    assign dst_valid = dst_valid_reg;

endmodule