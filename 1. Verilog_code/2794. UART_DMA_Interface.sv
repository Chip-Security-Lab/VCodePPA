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
// DMA控制状态机
localparam DMA_IDLE = 3'b000;
localparam DMA_REQ  = 3'b001;
localparam DMA_XFER = 3'b010;
localparam DMA_LAST = 3'b011;

// 添加缺失信号声明
reg [2:0] dma_state;
reg [7:0] burst_counter;
reg [MEM_WIDTH-1:0] addr_reg;
reg [MEM_WIDTH-1:0] base_addr;
reg tx_fifo_empty;
reg [7:0] data_segment [0:3];

// 数据重对齐逻辑
always @(*) begin
    case(addr_reg[1:0])
        2'b00: data_segment[0] = dma_data[31:24];
        2'b01: data_segment[0] = dma_data[23:16];
        2'b10: data_segment[0] = dma_data[15:8];
        2'b11: data_segment[0] = dma_data[7:0];
    endcase
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        dma_state <= DMA_IDLE;
        burst_counter <= 0;
        addr_reg <= 0;
        base_addr <= 0;
        dma_req <= 0;
        dma_addr <= 0;
        txd <= 1'b1;
        tx_fifo_empty <= 1'b1;
    end else if (dma_mode[0]) begin
        // 发送DMA状态机
        case(dma_state)
            DMA_IDLE: begin
                if (tx_fifo_empty) begin
                    dma_state <= DMA_REQ;
                    addr_reg <= base_addr;
                    dma_req <= 1'b1;
                end
            end
            DMA_REQ: begin
                if (dma_ack) begin
                    dma_req <= 1'b0;
                    dma_state <= DMA_XFER;
                    burst_counter <= 0;
                end
            end
            DMA_XFER: begin
                // 简化实现 - 发送数据到UART
                txd <= data_segment[0][7]; // 示例：发送最高位
                burst_counter <= burst_counter + 1;
                if (burst_counter == BURST_LEN-1) begin
                    dma_state <= DMA_LAST;
                end
            end
            DMA_LAST: begin
                dma_state <= DMA_IDLE;
                tx_fifo_empty <= 1'b0;
            end
            default: dma_state <= DMA_IDLE;
        endcase
    end
end
endmodule