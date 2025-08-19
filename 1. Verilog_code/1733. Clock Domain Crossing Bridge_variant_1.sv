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

    reg [DWIDTH-1:0] xfer_data;
    reg xfer_valid;
    reg xfer_ack;
    reg dst_ack;
    reg src_ack;
    reg [DWIDTH-1:0] src_data_reg;
    reg src_valid_reg;
    
    // Source domain data transfer
    always @(posedge src_clk or negedge rst_n) begin
        if (!rst_n) begin
            src_data_reg <= 0;
            src_valid_reg <= 0;
            xfer_data <= 0;
        end else begin
            src_data_reg <= src_data;
            src_valid_reg <= src_valid;
            if (src_valid_reg && !xfer_valid && !src_ack) begin
                xfer_data <= src_data_reg;
            end
        end
    end

    // Source domain valid control
    always @(posedge src_clk or negedge rst_n) begin
        if (!rst_n) begin
            xfer_valid <= 0;
        end else begin
            xfer_valid <= (src_valid_reg && !xfer_valid && !src_ack) ? 1'b1 : 
                         (xfer_ack) ? 1'b0 : xfer_valid;
        end
    end

    // Destination domain data transfer
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            dst_data <= 0;
        end else if (xfer_valid && !dst_valid && !xfer_ack) begin
            dst_data <= xfer_data;
        end
    end

    // Destination domain valid control
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            dst_valid <= 0;
        end else begin
            dst_valid <= (xfer_valid && !dst_valid && !xfer_ack) ? 1'b1 :
                        (dst_ready && dst_valid) ? 1'b0 : dst_valid;
        end
    end

    // Transfer acknowledge control
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            xfer_ack <= 0;
        end else begin
            xfer_ack <= (xfer_valid && !dst_valid && !xfer_ack) ? 1'b1 :
                       (dst_ready && dst_valid) ? 1'b0 : xfer_ack;
        end
    end

    assign src_ready = !xfer_valid;
endmodule