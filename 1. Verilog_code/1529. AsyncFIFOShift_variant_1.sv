//SystemVerilog
// SystemVerilog
// IEEE 1364-2005
module AsyncFIFOShift #(
    parameter DEPTH = 8,
    parameter AW    = $clog2(DEPTH)
)(
    input  wire wr_clk,
    input  wire rd_clk,
    input  wire wr_en,
    input  wire rd_en,
    input  wire din,
    output wire dout
);
    // 内部连接信号
    wire [AW-1:0] write_address;
    wire [AW-1:0] read_address;
    wire write_enable;
    wire [AW:0] wr_ptr, rd_ptr;
    
    // 为高扇出信号添加缓冲寄存器
    reg [AW-1:0] write_address_buf1, write_address_buf2;
    reg [AW-1:0] read_address_buf1, read_address_buf2;
    reg din_buf1, din_buf2;
    reg [AW-1:0] AW_buf1, AW_buf2;
    
    // AW缓冲寄存器更新
    always @(posedge wr_clk) begin
        AW_buf1 <= AW;
        AW_buf2 <= AW_buf1;
    end
    
    // din缓冲寄存器更新
    always @(posedge wr_clk) begin
        din_buf1 <= din;
        din_buf2 <= din_buf1;
    end
    
    // 写地址缓冲寄存器更新
    always @(posedge wr_clk) begin
        write_address_buf1 <= write_address;
        write_address_buf2 <= write_address_buf1;
    end
    
    // 读地址缓冲寄存器更新
    always @(posedge rd_clk) begin
        read_address_buf1 <= read_address;
        read_address_buf2 <= read_address_buf1;
    end
    
    // 写指针控制子模块
    WritePointerControl #(
        .AW(AW)
    ) write_ctrl (
        .clk(wr_clk),
        .enable(wr_en),
        .wr_ptr(wr_ptr),
        .write_address(write_address),
        .write_enable(write_enable)
    );
    
    // 读指针控制子模块
    ReadPointerControl #(
        .AW(AW)
    ) read_ctrl (
        .clk(rd_clk),
        .enable(rd_en),
        .rd_ptr(rd_ptr),
        .read_address(read_address)
    );
    
    // 存储器子模块
    MemoryStorage #(
        .DEPTH(DEPTH),
        .AW(AW)
    ) memory (
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .write_address(write_address_buf1),
        .read_address(read_address_buf1),
        .write_enable(write_enable),
        .din(din_buf1),
        .dout(dout)
    );
endmodule

// 写指针控制子模块
module WritePointerControl #(
    parameter AW = 3
)(
    input  wire clk,
    input  wire enable,
    output reg [AW:0] wr_ptr,
    output wire [AW-1:0] write_address,
    output wire write_enable
);
    // 缓冲寄存器用于高扇出信号
    reg [AW:0] wr_ptr_buf;
    
    // 初始化
    initial begin
        wr_ptr = {(AW+1){1'b0}};
        wr_ptr_buf = {(AW+1){1'b0}};
    end
    
    // 写地址解码
    assign write_address = wr_ptr_buf[AW-1:0];
    assign write_enable = enable;
    
    // 写指针更新逻辑
    always @(posedge clk) begin
        if (enable) begin
            wr_ptr <= wr_ptr + 1'b1;
        end
        // 更新缓冲寄存器以减少扇出
        wr_ptr_buf <= wr_ptr;
    end
endmodule

// 读指针控制子模块
module ReadPointerControl #(
    parameter AW = 3
)(
    input  wire clk,
    input  wire enable,
    output reg [AW:0] rd_ptr,
    output reg [AW-1:0] read_address
);
    // 缓冲寄存器用于高扇出信号
    reg [AW:0] rd_ptr_buf;
    reg [AW-1:0] read_address_pre;
    
    // 初始化
    initial begin
        rd_ptr = {(AW+1){1'b0}};
        rd_ptr_buf = {(AW+1){1'b0}};
        read_address = {AW{1'b0}};
        read_address_pre = {AW{1'b0}};
    end
    
    // 读指针和读地址更新逻辑
    always @(posedge clk) begin
        if (enable) begin
            rd_ptr <= rd_ptr + 1'b1;
            read_address_pre <= rd_ptr_buf[AW-1:0] + 1'b1; // 预计算下一个读地址
        end else begin
            read_address_pre <= rd_ptr_buf[AW-1:0]; // 保持当前读地址
        end
        
        // 更新缓冲寄存器以减少扇出
        rd_ptr_buf <= rd_ptr;
        read_address <= read_address_pre;
    end
endmodule

// 存储器子模块
module MemoryStorage #(
    parameter DEPTH = 8,
    parameter AW = 3
)(
    input  wire wr_clk,
    input  wire rd_clk,
    input  wire [AW-1:0] write_address,
    input  wire [AW-1:0] read_address,
    input  wire write_enable,
    input  wire din,
    output reg dout
);
    // 内存存储单元
    reg [DEPTH-1:0] mem;
    
    // 缓冲寄存器用于输出
    reg dout_pre;
    
    // 初始化
    initial begin
        mem = {DEPTH{1'b0}};
        dout = 1'b0;
        dout_pre = 1'b0;
    end
    
    // 写入逻辑
    always @(posedge wr_clk) begin
        if (write_enable) begin
            mem[write_address] <= din;
        end
    end
    
    // 读出逻辑使用两级寄存器减少扇出负载
    always @(posedge rd_clk) begin
        dout_pre <= mem[read_address];
        dout <= dout_pre;
    end
endmodule