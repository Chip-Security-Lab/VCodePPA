//SystemVerilog
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

localparam DMA_IDLE = 3'b000;
localparam DMA_REQ  = 3'b001;
localparam DMA_XFER = 3'b010;
localparam DMA_LAST = 3'b011;

reg [2:0] dma_state;
reg [7:0] burst_counter;
reg [MEM_WIDTH-1:0] addr_reg;
reg [MEM_WIDTH-1:0] base_addr;
reg tx_fifo_empty;
reg [7:0] data_segment [0:3];

// 优化后的数据重对齐逻辑，使用casez和范围检查
always @(*) begin
    casez (addr_reg[1:0])
        2'b00: data_segment[0] = dma_data[31:24];
        2'b01: data_segment[0] = dma_data[23:16];
        2'b10: data_segment[0] = dma_data[15:8];
        default: data_segment[0] = dma_data[7:0];
    endcase
end

// 8位先行借位减法器子模块声明
wire [7:0] burst_counter_sub;
wire       borrow_out;

BorrowLookaheadSubtractor8 u_burst_counter_subtractor (
    .minuend   (burst_counter),
    .subtrahend(8'd1),
    .diff      (burst_counter_sub),
    .borrow    (borrow_out)
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        dma_state      <= DMA_IDLE;
        burst_counter  <= 8'd0;
        addr_reg       <= {MEM_WIDTH{1'b0}};
        base_addr      <= {MEM_WIDTH{1'b0}};
        dma_req        <= 1'b0;
        dma_addr       <= {MEM_WIDTH{1'b0}};
        txd            <= 1'b1;
        tx_fifo_empty  <= 1'b1;
    end else if (dma_mode[1:0] == 2'b01) begin
        case (dma_state)
            DMA_IDLE: begin
                if (tx_fifo_empty) begin
                    dma_state     <= DMA_REQ;
                    addr_reg      <= base_addr;
                    dma_req       <= 1'b1;
                end
            end
            DMA_REQ: begin
                if (dma_ack) begin
                    dma_req       <= 1'b0;
                    dma_state     <= DMA_XFER;
                    burst_counter <= 8'd0;
                end
            end
            DMA_XFER: begin
                txd            <= data_segment[0][7];
                burst_counter  <= burst_counter_sub;
                if (burst_counter_sub >= (BURST_LEN-1)) begin
                    dma_state   <= DMA_LAST;
                end
            end
            DMA_LAST: begin
                dma_state     <= DMA_IDLE;
                tx_fifo_empty <= 1'b0;
            end
            default: dma_state <= DMA_IDLE;
        endcase
    end
end

endmodule

// 8位先行借位减法器实现
module BorrowLookaheadSubtractor8 (
    input  wire [7:0] minuend,
    input  wire [7:0] subtrahend,
    output wire [7:0] diff,
    output wire       borrow
);
    wire [7:0] generate_borrow;
    wire [7:0] propagate_borrow;
    wire [8:0] borrow_chain;

    assign borrow_chain[0] = 1'b0;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : SUB_LOOP
            assign generate_borrow[i]  = (~minuend[i]) & subtrahend[i];
            assign propagate_borrow[i] = (~minuend[i]) | subtrahend[i];
            assign borrow_chain[i+1]   = generate_borrow[i] | (propagate_borrow[i] & borrow_chain[i]);
            assign diff[i]             = minuend[i] ^ subtrahend[i] ^ borrow_chain[i];
        end
    endgenerate

    assign borrow = borrow_chain[8];
endmodule