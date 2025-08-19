//SystemVerilog
`timescale 1ns/1ps

module UART_DMA_Interface #(
    parameter BURST_LEN = 16,
    parameter MEM_WIDTH = 32
)(
    input  wire clk,
    input  wire rst,
    // DMA接口
    output reg  dma_req,
    input  wire dma_ack,
    output reg  [MEM_WIDTH-1:0] dma_addr,
    input  wire [MEM_WIDTH-1:0] dma_data,
    // UART物理接口
    output reg  txd,
    input  wire rxd,
    // 控制信号
    input  wire [1:0] dma_mode  // 00-停用 01-发送 10-接收
);

//////////////////////////////////////////////////////////////////////////////
// 高扇出信号缓冲寄存器定义
//////////////////////////////////////////////////////////////////////////////
reg dma_req_buf1, dma_req_buf2;
reg [MEM_WIDTH-1:0] dma_addr_buf1, dma_addr_buf2;
reg dma_idle_buf1, dma_idle_buf2;
reg [2:0] dma_state_reg, dma_state_buf1, dma_state_buf2;
reg [7:0] burst_counter_reg, burst_counter_buf1, burst_counter_buf2;

//////////////////////////////////////////////////////////////////////////////
// DMA控制状态机参数
//////////////////////////////////////////////////////////////////////////////
localparam DMA_IDLE_STATE = 3'b000;
localparam DMA_REQ_STATE  = 3'b001;
localparam DMA_XFER_STATE = 3'b010;
localparam DMA_LAST_STATE = 3'b011;

//////////////////////////////////////////////////////////////////////////////
// 信号声明
//////////////////////////////////////////////////////////////////////////////
reg [MEM_WIDTH-1:0] addr_reg;
reg [MEM_WIDTH-1:0] base_addr;
reg tx_fifo_empty;
wire [7:0] data_segment;
wire [1:0] addr_lsb;

assign addr_lsb = addr_reg[1:0];

//////////////////////////////////////////////////////////////////////////////
// 通用可复用字节选择子模块实例化
//////////////////////////////////////////////////////////////////////////////
ByteSelector #(
    .DATA_WIDTH(MEM_WIDTH)
) u_ByteSelector (
    .data_in(dma_data),
    .sel(addr_lsb),
    .data_out(data_segment)
);

//////////////////////////////////////////////////////////////////////////////
// 高扇出信号缓冲寄存器一级
//////////////////////////////////////////////////////////////////////////////
always @(posedge clk or posedge rst) begin
    if (rst) begin
        dma_req_buf1         <= 1'b0;
        dma_addr_buf1        <= {MEM_WIDTH{1'b0}};
        dma_idle_buf1        <= 1'b1;
        dma_state_buf1       <= DMA_IDLE_STATE;
        burst_counter_buf1   <= 8'd0;
    end else begin
        dma_req_buf1         <= dma_req;
        dma_addr_buf1        <= dma_addr;
        dma_idle_buf1        <= (dma_state_reg == DMA_IDLE_STATE);
        dma_state_buf1       <= dma_state_reg;
        burst_counter_buf1   <= burst_counter_reg;
    end
end

//////////////////////////////////////////////////////////////////////////////
// 高扇出信号缓冲寄存器二级
//////////////////////////////////////////////////////////////////////////////
always @(posedge clk or posedge rst) begin
    if (rst) begin
        dma_req_buf2         <= 1'b0;
        dma_addr_buf2        <= {MEM_WIDTH{1'b0}};
        dma_idle_buf2        <= 1'b1;
        dma_state_buf2       <= DMA_IDLE_STATE;
        burst_counter_buf2   <= 8'd0;
    end else begin
        dma_req_buf2         <= dma_req_buf1;
        dma_addr_buf2        <= dma_addr_buf1;
        dma_idle_buf2        <= dma_idle_buf1;
        dma_state_buf2       <= dma_state_buf1;
        burst_counter_buf2   <= burst_counter_buf1;
    end
end

//////////////////////////////////////////////////////////////////////////////
// 主时序控制逻辑与高扇出信号源寄存器
//////////////////////////////////////////////////////////////////////////////
always @(posedge clk or posedge rst) begin
    if (rst) begin
        dma_state_reg        <= DMA_IDLE_STATE;
        burst_counter_reg    <= 8'd0;
        addr_reg             <= {MEM_WIDTH{1'b0}};
        base_addr            <= {MEM_WIDTH{1'b0}};
        dma_req              <= 1'b0;
        dma_addr             <= {MEM_WIDTH{1'b0}};
        txd                  <= 1'b1;
        tx_fifo_empty        <= 1'b1;
    end else if (dma_mode == 2'b01) begin
        casez (dma_state_reg)
            DMA_IDLE_STATE: begin
                if (tx_fifo_empty) begin
                    dma_state_reg   <= DMA_REQ_STATE;
                    addr_reg        <= base_addr;
                    dma_addr        <= base_addr;
                    dma_req         <= 1'b1;
                end
            end
            DMA_REQ_STATE: begin
                if (dma_ack) begin
                    dma_req         <= 1'b0;
                    dma_state_reg   <= DMA_XFER_STATE;
                    burst_counter_reg <= 8'd0;
                end
            end
            DMA_XFER_STATE: begin
                txd                <= data_segment[7];
                burst_counter_reg  <= burst_counter_reg + 8'd1;
                addr_reg           <= addr_reg + 4;
                dma_addr           <= addr_reg + 4;
                if (burst_counter_reg >= (BURST_LEN-1)) begin
                    dma_state_reg   <= DMA_LAST_STATE;
                end
            end
            DMA_LAST_STATE: begin
                dma_state_reg      <= DMA_IDLE_STATE;
                tx_fifo_empty      <= 1'b0;
            end
            default: begin
                dma_state_reg      <= DMA_IDLE_STATE;
            end
        endcase
    end
end

endmodule

//////////////////////////////////////////////////////////////////////////////
// 通用可复用字节选择子模块
//////////////////////////////////////////////////////////////////////////////
module ByteSelector #(
    parameter DATA_WIDTH = 32
)(
    input  wire [DATA_WIDTH-1:0] data_in,
    input  wire [1:0]            sel,
    output reg  [7:0]            data_out
);
always @(*) begin
    case (sel)
        2'b00:    data_out = data_in[31:24];
        2'b01:    data_out = data_in[23:16];
        2'b10:    data_out = data_in[15:8];
        2'b11:    data_out = data_in[7:0];
        default:  data_out = 8'h00;
    endcase
end
endmodule