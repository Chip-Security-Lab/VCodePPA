//SystemVerilog
module shadow_reg_handshake #(parameter DW=32) (
    input src_clk, dst_clk,
    input req, ack,
    input [DW-1:0] src_data,
    output reg [DW-1:0] dst_data
);

    wire [DW-1:0] sync_data;
    wire req_sync;

    // Synchronization Module
    sync_module #(DW) u_sync (
        .clk(src_clk),
        .req(req),
        .src_data(src_data),
        .sync_data(sync_data)
    );

    // Acknowledgment Module
    ack_module #(DW) u_ack (
        .clk(dst_clk),
        .ack(ack),
        .sync_data(sync_data),
        .dst_data(dst_data),
        .req_sync(req_sync)
    );

endmodule

module sync_module #(parameter DW=32) (
    input clk,
    input req,
    input [DW-1:0] src_data,
    output reg [DW-1:0] sync_data
);
    always @(posedge clk) begin
        if(req) sync_data <= src_data;
    end
endmodule

module ack_module #(parameter DW=32) (
    input clk,
    input ack,
    input [DW-1:0] sync_data,
    output reg [DW-1:0] dst_data,
    output reg req_sync
);
    always @(posedge clk) begin
        req_sync <= ack; // Assuming req_sync is driven by ack for demonstration
        if(ack) dst_data <= sync_data;
    end
endmodule