//SystemVerilog

// 子模块：同步寄存器
module sync_reg #(parameter DW=32) (
    input clk,
    input req,
    input [DW-1:0] src_data,
    output reg [DW-1:0] sync_reg
);
    always @(posedge clk) begin
        if(req) begin
            sync_reg <= src_data;
        end
    end
endmodule

// 子模块：请求同步器
module req_sync #(parameter DW=32) (
    input clk,
    input req,
    output reg req_sync
);
    reg req_sync_meta;

    always @(posedge clk) begin
        req_sync_meta <= req;
        req_sync <= req_sync_meta;
    end
endmodule

// 顶层模块：shadow_reg_handshake
module shadow_reg_handshake #(parameter DW=32) (
    input src_clk, dst_clk,
    input req, ack,
    input [DW-1:0] src_data,
    output reg [DW-1:0] dst_data
);
    wire [DW-1:0] sync_data;
    wire req_sync;

    // 实例化同步寄存器
    sync_reg #(DW) sync_reg_inst (
        .clk(src_clk),
        .req(req),
        .src_data(src_data),
        .sync_reg(sync_data)
    );

    // 实例化请求同步器
    req_sync #(DW) req_sync_inst (
        .clk(dst_clk),
        .req(req),
        .req_sync(req_sync)
    );

    // 目标时钟域 - 数据采样逻辑
    always @(posedge dst_clk) begin
        if(ack && req_sync) begin
            dst_data <= sync_data;
        end
    end
endmodule