//SystemVerilog
module shadow_reg_handshake #(parameter DW=8) (
    input src_clk, dst_clk,
    input req, ack,
    input [DW-1:0] src_data,
    output reg [DW-1:0] dst_data
);
    reg [DW-1:0] sync_reg;
    reg req_sync;
    wire [DW-1:0] negated_data;

    // 计算补码
    assign negated_data = ~src_data + 1;

    always @(posedge src_clk) begin
        if(req) sync_reg <= negated_data; // 使用补码加法替代减法
    end
    
    always @(posedge dst_clk) begin
        req_sync <= req;
        if(ack) dst_data <= sync_reg;
    end
endmodule