//SystemVerilog
//========================================================
// 顶层模块：实现PingPong缓冲的跨时钟域数据传输
//========================================================
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
    wire src_sel;
    wire dst_sel;
    wire cdc_sync;
    wire [DATA_W-1:0] buf0;
    wire [DATA_W-1:0] buf1;

    // 源时钟域控制器
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

    // 跨时钟域同步器
    ClockDomainSync cdc_sync_inst (
        .src_clk(src_clk),
        .dst_clk(dst_clk),
        .src_sel(src_sel),
        .cdc_sync(cdc_sync)
    );

    // 目标时钟域控制器
    DestinationController #(
        .DATA_W(DATA_W)
    ) dst_ctrl (
        .clk(dst_clk),
        .buf0(buf0),
        .buf1(buf1),
        .cdc_sync(cdc_sync),
        .data_out(data_out),
        .valid_out(valid_out)
    );

endmodule

//========================================================
// 子模块：源时钟域数据写入控制器
//========================================================
module SourceController #(
    parameter DATA_W = 64
)(
    input clk,
    input [DATA_W-1:0] data_in,
    input valid_in,
    output reg [DATA_W-1:0] buf0,
    output reg [DATA_W-1:0] buf1,
    output reg src_sel
);
    // 初始化寄存器
    initial begin
        buf0 = {DATA_W{1'b0}};
        buf1 = {DATA_W{1'b0}};
        src_sel = 1'b0;
    end

    always @(posedge clk) begin
        if (valid_in) begin
            // 根据选择信号写入相应的缓冲区
            if (!src_sel) 
                buf0 <= data_in;
            else 
                buf1 <= data_in;
            
            // 切换缓冲区选择信号
            src_sel <= ~src_sel;
        end
    end
endmodule

//========================================================
// 子模块：跨时钟域同步器 (使用双触发器同步)
//========================================================
module ClockDomainSync (
    input src_clk,
    input dst_clk,
    input src_sel,
    output cdc_sync
);
    // 双触发器同步器
    reg sync_ff1;
    reg sync_ff2;
    
    always @(posedge dst_clk) begin
        sync_ff1 <= src_sel;
        sync_ff2 <= sync_ff1;
    end
    
    assign cdc_sync = sync_ff2;
endmodule

//========================================================
// 子模块：目标时钟域数据读取控制器
//========================================================
module DestinationController #(
    parameter DATA_W = 64
)(
    input clk,
    input [DATA_W-1:0] buf0,
    input [DATA_W-1:0] buf1,
    input cdc_sync,
    output reg [DATA_W-1:0] data_out,
    output valid_out
);
    reg dst_sel;
    
    // 初始化
    initial begin
        dst_sel = 1'b0;
        data_out = {DATA_W{1'b0}};
    end

    always @(posedge clk) begin
        // 更新接收端选择信号
        dst_sel <= cdc_sync;
        
        // 根据选择信号读取对应缓冲区的数据
        data_out <= dst_sel ? buf1 : buf0;
    end
    
    // 当选择信号与同步信号不同时表示有新数据
    assign valid_out = (dst_sel != cdc_sync);
endmodule