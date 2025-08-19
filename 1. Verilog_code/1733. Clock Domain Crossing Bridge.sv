module cdc_bus_bridge #(parameter DWIDTH=32) (
    input src_clk, dst_clk, rst_n,
    input [DWIDTH-1:0] src_data,
    input src_valid,
    output src_ready,
    output reg [DWIDTH-1:0] dst_data,
    output reg dst_valid,
    input dst_ready
);
    reg [DWIDTH-1:0] xfer_data;
    reg xfer_valid, xfer_ack;
    reg dst_ack, src_ack;
    
    // Source domain logic
    always @(posedge src_clk or negedge rst_n) begin
        if (!rst_n) begin
            xfer_data <= 0; xfer_valid <= 0;
        end else if (src_valid && !xfer_valid && !src_ack) begin
            xfer_data <= src_data; xfer_valid <= 1;
        end else if (xfer_ack) begin
            xfer_valid <= 0;
        end
    end
    
    // Destination domain logic
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            dst_data <= 0; dst_valid <= 0; xfer_ack <= 0;
        end else if (xfer_valid && !dst_valid && !xfer_ack) begin
            dst_data <= xfer_data; dst_valid <= 1; xfer_ack <= 1;
        end else if (dst_ready && dst_valid) begin
            dst_valid <= 0; xfer_ack <= 0;
        end
    end
    
    assign src_ready = !xfer_valid;
endmodule