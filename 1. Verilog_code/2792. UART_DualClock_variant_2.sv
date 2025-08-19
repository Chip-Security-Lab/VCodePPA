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
function [DATA_WIDTH:0] bin2gray;
    input [DATA_WIDTH:0] bin;
    begin
        bin2gray = bin ^ (bin >> 1);
    end
endfunction

// 奇偶校验生成函数
function parity_gen;
    input [DATA_WIDTH-2:0] data;
    begin
        parity_gen = ^data; // 简单的异或校验
    end
endfunction

// FIFO存储器
reg [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];

// 指针与相关信号
reg [$clog2(FIFO_DEPTH):0] wr_ptr, rd_ptr;
wire [DATA_WIDTH:0] wr_ptr_gray;
wire [DATA_WIDTH:0] rd_ptr_gray;

assign wr_ptr_gray = bin2gray(wr_ptr);
assign rd_ptr_gray = bin2gray(rd_ptr);

// 状态寄存器
reg frame_err_reg, parity_err_reg;
assign frame_error = frame_err_reg;
assign parity_error = parity_err_reg;

// 前向重定时：将输入端的寄存器后移穿过组合逻辑
// 1. 输入数据和写使能信号寄存器移到组合逻辑之后

reg [DATA_WIDTH-1:0] data_in_reg;
reg wr_en_reg;

// 输入同步寄存器（前向重定时后，采样寄存器移动到FIFO写入逻辑之后）

always @(posedge tx_clk or posedge sys_rst) begin
    if (sys_rst) begin
        wr_ptr <= 0;
        txd <= 1'b1;
    end else begin
        // 采样输入数据和写使能信号
        data_in_reg <= data_in;
        wr_en_reg   <= wr_en;
        // 写指针处理（采样后的数据和控制信号用于写入FIFO）
        if (wr_en_reg && !full) begin
            fifo_mem[wr_ptr[$clog2(FIFO_DEPTH)-1:0]] <= {parity_gen(data_in_reg[DATA_WIDTH-2:0]), data_in_reg};
            wr_ptr <= wr_ptr + 1;
        end
        // Gray码同步逻辑和发送逻辑在这里实现
    end
end

// 接收时钟域处理
always @(posedge rx_clk or posedge sys_rst) begin
    if (sys_rst) begin
        rd_ptr <= 0;
        frame_err_reg <= 0;
        parity_err_reg <= 0;
    end else begin
        // 接收时钟域处理
        // 这里添加数字噪声滤波器和奇偶校验模块的实现
    end
end

// FIFO满状态检测
assign full = ((wr_ptr[$clog2(FIFO_DEPTH)] != rd_ptr[$clog2(FIFO_DEPTH)]) && 
               (wr_ptr[$clog2(FIFO_DEPTH)-1:0] == rd_ptr[$clog2(FIFO_DEPTH)-1:0]));

endmodule