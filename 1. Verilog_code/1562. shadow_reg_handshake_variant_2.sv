//SystemVerilog
//顶层模块
module shadow_reg_handshake #(parameter DW=32) (
    input src_clk, dst_clk,
    input req, ack,
    input [DW-1:0] src_data,
    output [DW-1:0] dst_data
);
    wire [DW-1:0] sync_reg;
    wire req_sync;
    
    // 源时钟域数据捕获子模块
    src_domain_capture #(
        .DW(DW)
    ) src_capture_inst (
        .src_clk(src_clk),
        .req(req),
        .src_data(src_data),
        .sync_reg(sync_reg)
    );
    
    // 目标时钟域数据同步子模块
    dst_domain_sync #(
        .DW(DW)
    ) dst_sync_inst (
        .dst_clk(dst_clk),
        .req(req),
        .ack(ack),
        .sync_reg(sync_reg),
        .req_sync(req_sync),
        .dst_data(dst_data)
    );
    
endmodule

// 源时钟域数据捕获子模块
module src_domain_capture #(parameter DW=32) (
    input src_clk,
    input req,
    input [DW-1:0] src_data,
    output reg [DW-1:0] sync_reg
);
    always @(posedge src_clk) begin
        if(req) sync_reg <= src_data;
    end
endmodule

// 目标时钟域数据同步子模块
module dst_domain_sync #(parameter DW=32) (
    input dst_clk,
    input req,
    input ack,
    input [DW-1:0] sync_reg,
    output reg req_sync,
    output reg [DW-1:0] dst_data
);
    always @(posedge dst_clk) begin
        req_sync <= req;
        if(ack) dst_data <= sync_reg;
    end
endmodule