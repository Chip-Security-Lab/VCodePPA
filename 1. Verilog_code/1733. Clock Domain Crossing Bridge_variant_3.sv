//SystemVerilog
module cdc_bus_bridge #(parameter DWIDTH=32) (
    input src_clk, dst_clk, rst_n,
    input [DWIDTH-1:0] src_data,
    input src_valid,
    output src_ready,
    output reg [DWIDTH-1:0] dst_data,
    output reg dst_valid,
    input dst_ready
);

    // Source domain pipeline registers
    reg [DWIDTH-1:0] src_data_stage1;
    reg src_valid_stage1;
    reg src_ready_stage1;
    
    // Transfer domain pipeline registers
    reg [DWIDTH-1:0] xfer_data_stage1;
    reg xfer_valid_stage1;
    reg xfer_ack_stage1;
    
    reg [DWIDTH-1:0] xfer_data_stage2;
    reg xfer_valid_stage2;
    reg xfer_ack_stage2;
    
    // Destination domain pipeline registers
    reg [DWIDTH-1:0] dst_data_stage1;
    reg dst_valid_stage1;
    reg dst_ready_stage1;
    
    // Source domain pipeline stage 1
    always @(posedge src_clk or negedge rst_n) begin
        if (!rst_n) begin
            src_data_stage1 <= 0;
            src_valid_stage1 <= 0;
            src_ready_stage1 <= 1;
        end else begin
            src_data_stage1 <= src_data;
            src_valid_stage1 <= src_valid;
            src_ready_stage1 <= !xfer_valid_stage1;
        end
    end
    
    // Transfer domain pipeline stage 1
    always @(posedge src_clk or negedge rst_n) begin
        if (!rst_n) begin
            xfer_data_stage1 <= 0;
            xfer_valid_stage1 <= 0;
        end else if (src_valid_stage1 && !xfer_valid_stage1 && !xfer_ack_stage1) begin
            xfer_data_stage1 <= src_data_stage1;
            xfer_valid_stage1 <= 1;
        end else if (xfer_ack_stage1) begin
            xfer_valid_stage1 <= 0;
        end
    end
    
    // Transfer domain pipeline stage 2
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            xfer_data_stage2 <= 0;
            xfer_valid_stage2 <= 0;
            xfer_ack_stage1 <= 0;
        end else begin
            xfer_data_stage2 <= xfer_data_stage1;
            xfer_valid_stage2 <= xfer_valid_stage1;
            xfer_ack_stage1 <= xfer_ack_stage2;
        end
    end
    
    // Destination domain pipeline stage 1
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            dst_data_stage1 <= 0;
            dst_valid_stage1 <= 0;
            dst_ready_stage1 <= 0;
            xfer_ack_stage2 <= 0;
        end else begin
            dst_data_stage1 <= xfer_data_stage2;
            dst_valid_stage1 <= xfer_valid_stage2;
            dst_ready_stage1 <= dst_ready;
            xfer_ack_stage2 <= dst_ready_stage1 && dst_valid_stage1;
        end
    end
    
    // Destination domain pipeline stage 2
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            dst_data <= 0;
            dst_valid <= 0;
        end else begin
            dst_data <= dst_data_stage1;
            dst_valid <= dst_valid_stage1;
        end
    end
    
    assign src_ready = src_ready_stage1;
endmodule