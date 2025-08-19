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

    wire [DWIDTH-1:0] xfer_data;
    wire xfer_valid, xfer_ack;

    // Instantiate source domain logic
    source_domain #(.DWIDTH(DWIDTH)) src_domain (
        .clk(src_clk),
        .rst_n(rst_n),
        .src_data(src_data),
        .src_valid(src_valid),
        .src_ready(src_ready),
        .xfer_data(xfer_data),
        .xfer_valid(xfer_valid),
        .xfer_ack(xfer_ack)
    );

    // Instantiate destination domain logic
    destination_domain #(.DWIDTH(DWIDTH)) dst_domain (
        .clk(dst_clk),
        .rst_n(rst_n),
        .xfer_data(xfer_data),
        .xfer_valid(xfer_valid),
        .dst_ready(dst_ready),
        .dst_data(dst_data),
        .dst_valid(dst_valid),
        .xfer_ack(xfer_ack)
    );

endmodule

// Source Domain Logic Module
module source_domain #(parameter DWIDTH=32) (
    input clk,
    input rst_n,
    input [DWIDTH-1:0] src_data,
    input src_valid,
    output reg src_ready,
    output reg [DWIDTH-1:0] xfer_data,
    output reg xfer_valid,
    output reg xfer_ack
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xfer_data <= 0; 
            xfer_valid <= 0;
            src_ready <= 1;
        end else if (src_valid && !xfer_valid && !xfer_ack) begin
            xfer_data <= src_data; 
            xfer_valid <= 1; 
            src_ready <= 0;
        end else if (xfer_ack) begin
            xfer_valid <= 0; 
            src_ready <= 1;
        end
    end
endmodule

// Destination Domain Logic Module
module destination_domain #(parameter DWIDTH=32) (
    input clk,
    input rst_n,
    input [DWIDTH-1:0] xfer_data,
    input xfer_valid,
    input dst_ready,
    output reg [DWIDTH-1:0] dst_data,
    output reg dst_valid,
    output reg xfer_ack
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dst_data <= 0; 
            dst_valid <= 0; 
            xfer_ack <= 0;
        end else if (xfer_valid && !dst_valid && !xfer_ack) begin
            dst_data <= xfer_data; 
            dst_valid <= 1; 
            xfer_ack <= 1;
        end else if (dst_ready && dst_valid) begin
            dst_valid <= 0; 
            xfer_ack <= 0;
        end
    end
endmodule