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

    // Stage 1: Source domain pipeline registers
    reg [DWIDTH-1:0] src_data_stage1;
    reg src_valid_stage1;
    reg src_ready_stage1;
    
    // Stage 2: Transfer domain pipeline registers
    reg [DWIDTH-1:0] xfer_data_stage2;
    reg xfer_valid_stage2;
    reg xfer_ack_stage2;
    
    // Stage 3: Destination domain pipeline registers
    reg [DWIDTH-1:0] dst_data_stage3;
    reg dst_valid_stage3;
    reg dst_ready_stage3;

    // Source domain pipeline stage
    always @(posedge src_clk or negedge rst_n) begin
        if (!rst_n) begin
            src_data_stage1 <= 0;
            src_valid_stage1 <= 0;
            src_ready_stage1 <= 1;
        end else begin
            if (src_valid && src_ready_stage1) begin
                src_data_stage1 <= src_data;
                src_valid_stage1 <= 1;
                src_ready_stage1 <= 0;
            end else if (!src_valid_stage1) begin
                src_ready_stage1 <= 1;
            end
        end
    end

    // Transfer domain pipeline stage
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            xfer_data_stage2 <= 0;
            xfer_valid_stage2 <= 0;
            xfer_ack_stage2 <= 0;
        end else begin
            if (src_valid_stage1 && !xfer_valid_stage2) begin
                xfer_data_stage2 <= src_data_stage1;
                xfer_valid_stage2 <= 1;
                xfer_ack_stage2 <= 0;
            end else if (dst_ready_stage3 && xfer_valid_stage2) begin
                xfer_valid_stage2 <= 0;
                xfer_ack_stage2 <= 1;
            end
        end
    end

    // Destination domain pipeline stage
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            dst_data_stage3 <= 0;
            dst_valid_stage3 <= 0;
            dst_ready_stage3 <= 0;
        end else begin
            if (xfer_valid_stage2 && !dst_valid_stage3) begin
                dst_data_stage3 <= xfer_data_stage2;
                dst_valid_stage3 <= 1;
            end else if (dst_ready && dst_valid_stage3) begin
                dst_valid_stage3 <= 0;
            end
            dst_ready_stage3 <= dst_ready;
        end
    end

    // Output assignments
    assign src_ready = src_ready_stage1;
    assign dst_data = dst_data_stage3;
    assign dst_valid = dst_valid_stage3;

endmodule