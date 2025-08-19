//SystemVerilog
module UART_DualClock #(
    parameter DATA_WIDTH = 9,
    parameter FIFO_DEPTH = 16,
    parameter SYNC_STAGES = 3
)(
    input  wire tx_clk,
    input  wire rx_clk,
    input  wire sys_rst,
    // 系统接口
    input  wire [DATA_WIDTH-1:0] data_in,
    input  wire wr_en,
    output wire full,
    // 物理接口
    output reg  txd,
    input  wire rxd,
    // 状态指示
    output wire frame_error,
    output wire parity_error
);

// Gray码转换函数
function [DATA_WIDTH:0] bin2gray_func;
    input [DATA_WIDTH:0] bin;
    begin
        bin2gray_func = bin ^ (bin >> 1);
    end
endfunction

// 奇偶校验生成函数
function parity_gen_func;
    input [DATA_WIDTH-2:0] data;
    begin
        parity_gen_func = ^data;
    end
endfunction

// FIFO存储器
reg [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];

// 写指针、读指针
reg [$clog2(FIFO_DEPTH):0] wr_ptr_reg, rd_ptr_reg;
wire [$clog2(FIFO_DEPTH):0] wr_ptr_next, rd_ptr_next;

// ---------- 扇出缓冲寄存器插入点 BEGIN ---------- //
// wr_ptr_reg缓冲
reg [$clog2(FIFO_DEPTH):0] wr_ptr_buf1;
reg [$clog2(FIFO_DEPTH):0] wr_ptr_buf2;

// bin2gray缓冲
reg [DATA_WIDTH:0] bin2gray_buf1_wr;
reg [DATA_WIDTH:0] bin2gray_buf2_wr;
reg [DATA_WIDTH:0] bin2gray_buf1_rd;
reg [DATA_WIDTH:0] bin2gray_buf2_rd;

// clog2缓冲（用于指针相关逻辑的负载均衡）
reg [$clog2(FIFO_DEPTH):0] clog2_buf1_wr;
reg [$clog2(FIFO_DEPTH):0] clog2_buf2_wr;
reg [$clog2(FIFO_DEPTH):0] clog2_buf1_rd;
reg [$clog2(FIFO_DEPTH):0] clog2_buf2_rd;
// ---------- 扇出缓冲寄存器插入点 END ------------ //

// Gray码指针
wire [DATA_WIDTH:0] wr_ptr_gray_int;
wire [DATA_WIDTH:0] rd_ptr_gray_int;

// 同步链
reg [DATA_WIDTH+1:0] sync_chain [0:SYNC_STAGES-1];

// 错误寄存器
reg frame_err_reg, parity_err_reg;

// 前向寄存器重定时
reg [DATA_WIDTH-1:0] data_in_reg;
reg wr_en_reg;

// 优化后的满检测信号(提前计算，简化比较链)
wire [$clog2(FIFO_DEPTH)-1:0] wr_ptr_cmp;
wire [$clog2(FIFO_DEPTH)-1:0] rd_ptr_cmp;
wire wr_ptr_msb, rd_ptr_msb;
wire full_int;

assign wr_ptr_cmp = clog2_buf2_wr[$clog2(FIFO_DEPTH)-1:0];
assign rd_ptr_cmp = clog2_buf2_rd[$clog2(FIFO_DEPTH)-1:0];
assign wr_ptr_msb = clog2_buf2_wr[$clog2(FIFO_DEPTH)];
assign rd_ptr_msb = clog2_buf2_rd[$clog2(FIFO_DEPTH)];

// 输入数据寄存器
always @(posedge tx_clk or posedge sys_rst) begin
    if (sys_rst) begin
        data_in_reg <= {DATA_WIDTH{1'b0}};
        wr_en_reg <= 1'b0;
    end else begin
        data_in_reg <= data_in;
        wr_en_reg  <= wr_en;
    end
end

// 写指针缓冲
always @(posedge tx_clk or posedge sys_rst) begin
    if (sys_rst) begin
        wr_ptr_buf1 <= {($clog2(FIFO_DEPTH)+1){1'b0}};
        wr_ptr_buf2 <= {($clog2(FIFO_DEPTH)+1){1'b0}};
    end else begin
        wr_ptr_buf1 <= wr_ptr_reg;
        wr_ptr_buf2 <= wr_ptr_buf1;
    end
end

// clog2缓冲（wr_ptr_reg相关）
always @(posedge tx_clk or posedge sys_rst) begin
    if (sys_rst) begin
        clog2_buf1_wr <= {($clog2(FIFO_DEPTH)+1){1'b0}};
        clog2_buf2_wr <= {($clog2(FIFO_DEPTH)+1){1'b0}};
    end else begin
        clog2_buf1_wr <= wr_ptr_reg;
        clog2_buf2_wr <= clog2_buf1_wr;
    end
end

// bin2gray缓冲（wr_ptr_reg相关）
always @(posedge tx_clk or posedge sys_rst) begin
    if (sys_rst) begin
        bin2gray_buf1_wr <= {(DATA_WIDTH+1){1'b0}};
        bin2gray_buf2_wr <= {(DATA_WIDTH+1){1'b0}};
    end else begin
        bin2gray_buf1_wr <= bin2gray_func(wr_ptr_reg);
        bin2gray_buf2_wr <= bin2gray_buf1_wr;
    end
end

// 读指针缓冲
always @(posedge rx_clk or posedge sys_rst) begin
    if (sys_rst) begin
        clog2_buf1_rd <= {($clog2(FIFO_DEPTH)+1){1'b0}};
        clog2_buf2_rd <= {($clog2(FIFO_DEPTH)+1){1'b0}};
        bin2gray_buf1_rd <= {(DATA_WIDTH+1){1'b0}};
        bin2gray_buf2_rd <= {(DATA_WIDTH+1){1'b0}};
    end else begin
        clog2_buf1_rd <= rd_ptr_reg;
        clog2_buf2_rd <= clog2_buf1_rd;
        bin2gray_buf1_rd <= bin2gray_func(rd_ptr_reg);
        bin2gray_buf2_rd <= bin2gray_buf1_rd;
    end
end

// 写指针处理
always @(posedge tx_clk or posedge sys_rst) begin
    if (sys_rst) begin
        wr_ptr_reg <= {($clog2(FIFO_DEPTH)+1){1'b0}};
        txd <= 1'b1;
    end else begin
        if (wr_en_reg && !full_int) begin
            fifo_mem[wr_ptr_reg[$clog2(FIFO_DEPTH)-1:0]] <= {parity_gen_func(data_in_reg[DATA_WIDTH-2:0]), data_in_reg};
            wr_ptr_reg <= wr_ptr_reg + 1;
        end
        // Gray码同步逻辑和发送逻辑可在此扩展
    end
end

// 读指针处理
always @(posedge rx_clk or posedge sys_rst) begin
    if (sys_rst) begin
        rd_ptr_reg <= {($clog2(FIFO_DEPTH)+1){1'b0}};
        frame_err_reg <= 1'b0;
        parity_err_reg <= 1'b0;
    end else begin
        // 接收时钟域处理
        // 可在此扩展数字噪声滤波器和奇偶校验模块
    end
end

// Gray码指针赋值（通过缓冲输出）
assign wr_ptr_gray_int = bin2gray_func(wr_ptr_reg);
assign rd_ptr_gray_int = bin2gray_func(rd_ptr_reg);

assign wr_ptr_gray = bin2gray_buf2_wr; // 使用二级缓冲输出
assign rd_ptr_gray = bin2gray_buf2_rd; // 使用二级缓冲输出

// 优化后的FIFO满检测
// 满条件：最高位不同，低位相同，等价于写指针跨越读指针一圈
assign full_int = (wr_ptr_msb ^ rd_ptr_msb) && (wr_ptr_cmp == rd_ptr_cmp);
assign full = full_int;

// 错误信号输出
assign frame_error = frame_err_reg;
assign parity_error = parity_err_reg;

endmodule