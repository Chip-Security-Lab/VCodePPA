//SystemVerilog
//-----------------------------------------------------------------------------
// 顶层模块: circular_buffer
//-----------------------------------------------------------------------------
module circular_buffer #(
    parameter DW = 16,
    parameter DEPTH = 8,
    parameter PTR_WIDTH = $clog2(DEPTH) + 1
)(
    input clk,
    input rst,
    input push,
    input pop,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output full,
    output empty
);
    // 内部连线
    wire [PTR_WIDTH-1:0] wptr, rptr;
    wire [PTR_WIDTH-1:0] wptr_next, rptr_next;
    wire wr_en, rd_en;
    
    // 状态检测模块实例化
    buffer_status_detector #(
        .PTR_WIDTH(PTR_WIDTH),
        .ADDR_WIDTH(PTR_WIDTH-1)
    ) status_unit (
        .wptr(wptr),
        .rptr(rptr),
        .push(push),
        .pop(pop),
        .full(full),
        .empty(empty),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .wptr_next(wptr_next),
        .rptr_next(rptr_next)
    );
    
    // 指针控制模块实例化
    pointer_controller #(
        .PTR_WIDTH(PTR_WIDTH)
    ) ptr_ctrl (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .wptr_next(wptr_next),
        .rptr_next(rptr_next),
        .wptr(wptr),
        .rptr(rptr)
    );
    
    // 存储器模块实例化
    buffer_memory #(
        .DW(DW),
        .DEPTH(DEPTH),
        .ADDR_WIDTH(PTR_WIDTH-1)
    ) memory_unit (
        .clk(clk),
        .wr_en(wr_en),
        .waddr(wptr[PTR_WIDTH-2:0]),
        .raddr(rptr[PTR_WIDTH-2:0]),
        .wdata(din),
        .rdata(dout)
    );

endmodule

//-----------------------------------------------------------------------------
// 子模块: 缓冲区状态检测器
//-----------------------------------------------------------------------------
module buffer_status_detector #(
    parameter PTR_WIDTH = 4,
    parameter ADDR_WIDTH = 3
)(
    input [PTR_WIDTH-1:0] wptr,
    input [PTR_WIDTH-1:0] rptr,
    input push,
    input pop,
    output full,
    output empty,
    output wr_en,
    output rd_en,
    output [PTR_WIDTH-1:0] wptr_next,
    output [PTR_WIDTH-1:0] rptr_next
);
    // 计算下一个指针值
    assign wptr_next = wptr + 1'b1;
    assign rptr_next = rptr + 1'b1;
    
    // 缓冲区状态计算
    assign full = (wptr[ADDR_WIDTH-1:0] == rptr[ADDR_WIDTH-1:0]) && (wptr[PTR_WIDTH-1] != rptr[PTR_WIDTH-1]);
    assign empty = (wptr == rptr);
    
    // 写入/读取使能信号
    assign wr_en = push && !full;
    assign rd_en = pop && !empty;
    
endmodule

//-----------------------------------------------------------------------------
// 子模块: 指针控制器
//-----------------------------------------------------------------------------
module pointer_controller #(
    parameter PTR_WIDTH = 4
)(
    input clk,
    input rst,
    input wr_en,
    input rd_en,
    input [PTR_WIDTH-1:0] wptr_next,
    input [PTR_WIDTH-1:0] rptr_next,
    output reg [PTR_WIDTH-1:0] wptr,
    output reg [PTR_WIDTH-1:0] rptr
);
    // 指针更新逻辑
    always @(posedge clk) begin
        if (rst) begin
            wptr <= {PTR_WIDTH{1'b0}};
            rptr <= {PTR_WIDTH{1'b0}};
        end else begin
            if (wr_en) begin
                wptr <= wptr_next;
            end
            if (rd_en) begin
                rptr <= rptr_next;
            end
        end
    end
    
endmodule

//-----------------------------------------------------------------------------
// 子模块: 缓冲区存储器
//-----------------------------------------------------------------------------
module buffer_memory #(
    parameter DW = 16,
    parameter DEPTH = 8,
    parameter ADDR_WIDTH = 3
)(
    input clk,
    input wr_en,
    input [ADDR_WIDTH-1:0] waddr,
    input [ADDR_WIDTH-1:0] raddr,
    input [DW-1:0] wdata,
    output [DW-1:0] rdata
);
    // 存储器定义
    reg [DW-1:0] mem [0:DEPTH-1];
    
    // 写入逻辑
    always @(posedge clk) begin
        if (wr_en) begin
            mem[waddr] <= wdata;
        end
    end
    
    // 读取逻辑
    assign rdata = mem[raddr];
    
endmodule