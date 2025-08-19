//SystemVerilog
module PingPongBridge #(
    parameter DATA_W = 64
)(
    input src_clk, dst_clk, 
    input [DATA_W-1:0] data_in,
    input valid_in,
    output [DATA_W-1:0] data_out,
    output valid_out
);
    // 内部连线
    wire [DATA_W-1:0] buf0, buf1;
    wire src_sel, dst_sel;
    wire cdc_sync;
    
    // 源时钟域写入控制器
    SourceController #(
        .DATA_W(DATA_W)
    ) src_ctrl (
        .clk(src_clk),
        .data_in(data_in),
        .valid_in(valid_in),
        .buf0(buf0),
        .buf1(buf1),
        .src_sel(src_sel)
    );
    
    // 时钟域同步器
    SyncController sync_ctrl (
        .src_sel(src_sel),
        .dst_clk(dst_clk),
        .cdc_sync(cdc_sync)
    );
    
    // 目标时钟域读取控制器
    DestController #(
        .DATA_W(DATA_W)
    ) dst_ctrl (
        .clk(dst_clk),
        .buf0(buf0),
        .buf1(buf1),
        .cdc_sync(cdc_sync),
        .data_out(data_out),
        .valid_out(valid_out),
        .dst_sel(dst_sel)
    );
endmodule

module SourceController #(
    parameter DATA_W = 64
)(
    input clk,
    input [DATA_W-1:0] data_in,
    input valid_in,
    output reg [DATA_W-1:0] buf0, buf1,
    output reg src_sel
);
    // 初始化寄存器
    initial begin
        buf0 = 0;
        buf1 = 0;
        src_sel = 0;
    end

    // 双缓冲写入逻辑
    always @(posedge clk) begin
        if (valid_in) begin
            if (!src_sel) buf0 <= data_in;
            else buf1 <= data_in;
            src_sel <= ~src_sel;
        end
    end
endmodule

module SyncController (
    input src_sel,
    input dst_clk,
    output cdc_sync
);
    // 2-FF同步器
    reg sync_ff1, sync_ff2;
    
    // 初始化寄存器
    initial begin
        sync_ff1 = 0;
        sync_ff2 = 0;
    end
    
    always @(posedge dst_clk) begin
        sync_ff1 <= src_sel;
        sync_ff2 <= sync_ff1;
    end
    
    assign cdc_sync = sync_ff2;
endmodule

module DestController #(
    parameter DATA_W = 64
)(
    input clk,
    input [DATA_W-1:0] buf0, buf1,
    input cdc_sync,
    output reg [DATA_W-1:0] data_out,
    output valid_out,
    output reg dst_sel
);
    // 初始化寄存器
    initial begin
        dst_sel = 0;
        data_out = 0;
    end
    
    // 目标时钟域读取逻辑
    always @(posedge clk) begin
        dst_sel <= cdc_sync;
        data_out <= dst_sel ? buf1 : buf0;
    end
    
    // 有效信号生成
    assign valid_out = (dst_sel != cdc_sync);
endmodule