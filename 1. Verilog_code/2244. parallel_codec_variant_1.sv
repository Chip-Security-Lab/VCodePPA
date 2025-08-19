//SystemVerilog
// 顶层模块
module parallel_codec #(
    parameter DW=16, AW=4, DEPTH=8
)(
    input  wire clk,
    input  wire valid,
    input  wire ready,
    input  wire [DW-1:0] din,
    output wire [DW-1:0] dout,
    output wire ack
);
    // 内部信号
    wire [AW-1:0] wr_ptr, rd_ptr, next_wr_ptr;
    wire is_empty;
    wire write_en, read_en;
    
    // 控制单元 - 管理读写使能和空状态
    codec_controller #(
        .AW(AW)
    ) ctrl_unit (
        .clk(clk),
        .valid(valid),
        .ready(ready),
        .is_empty(is_empty),
        .wr_ptr(wr_ptr),
        .rd_ptr(rd_ptr),
        .next_wr_ptr(next_wr_ptr),
        .write_en(write_en),
        .read_en(read_en),
        .ack(ack)
    );
    
    // 数据路径单元 - 管理数据存储和指针
    codec_datapath #(
        .DW(DW),
        .AW(AW),
        .DEPTH(DEPTH)
    ) data_unit (
        .clk(clk),
        .write_en(write_en),
        .read_en(read_en),
        .din(din),
        .wr_ptr(wr_ptr),
        .rd_ptr(rd_ptr),
        .next_wr_ptr(next_wr_ptr),
        .is_empty(is_empty),
        .dout(dout)
    );
    
endmodule

// 控制器模块 - 负责控制信号生成和状态管理
module codec_controller #(
    parameter AW=4
)(
    input  wire clk,
    input  wire valid,
    input  wire ready,
    input  wire is_empty,
    input  wire [AW-1:0] wr_ptr,
    input  wire [AW-1:0] rd_ptr,
    output wire [AW-1:0] next_wr_ptr,
    output reg  write_en,
    output reg  read_en,
    output reg  ack
);
    // 计算下一个写指针以减少关键路径延迟
    assign next_wr_ptr = wr_ptr + 1'b1;
    
    // 控制信号生成
    always @(posedge clk) begin
        // 写使能信号
        write_en <= valid && ready;
        
        // 读使能信号
        read_en <= !is_empty;
        
        // 确认信号生成
        ack <= !is_empty;
    end
    
endmodule

// 数据路径模块 - 负责数据存储和指针管理
module codec_datapath #(
    parameter DW=16, AW=4, DEPTH=8
)(
    input  wire clk,
    input  wire write_en,
    input  wire read_en,
    input  wire [DW-1:0] din,
    output reg  [AW-1:0] wr_ptr,
    output reg  [AW-1:0] rd_ptr,
    input  wire [AW-1:0] next_wr_ptr,
    output reg  is_empty,
    output reg  [DW-1:0] dout
);
    // 缓冲区内存
    reg [DW-1:0] buffer [0:DEPTH-1];
    
    // 指针管理和数据传输
    always @(posedge clk) begin
        // 更新空状态标志
        is_empty <= (next_wr_ptr == rd_ptr + (read_en ? 1'b1 : 1'b0));
        
        // 写操作
        if(write_en) begin
            buffer[wr_ptr] <= din;
            wr_ptr <= next_wr_ptr;
        end
        
        // 读操作
        if(read_en) begin
            dout <= buffer[rd_ptr];
            rd_ptr <= rd_ptr + 1'b1;
        end
    end
    
endmodule