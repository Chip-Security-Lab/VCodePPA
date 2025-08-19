module shadow_reg_handshake #(parameter DW=32) (
    input src_clk, dst_clk,
    input req, ack,
    input [DW-1:0] src_data,
    output reg [DW-1:0] dst_data
);
    reg [DW-1:0] sync_reg;
    reg req_sync;
    
    always @(posedge src_clk) begin
        if(req) sync_reg <= src_data;
    end
    
    always @(posedge dst_clk) begin
        req_sync <= req;
        if(ack) dst_data <= sync_reg;
    end
endmodule