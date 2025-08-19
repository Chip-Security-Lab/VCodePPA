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

// DMA控制状态机
localparam DMA_IDLE = 3'b000;
localparam DMA_REQ  = 3'b001;
localparam DMA_XFER = 3'b010;
localparam DMA_LAST = 3'b011;

// 优化后的信号声明
reg [2:0] dma_state_reg, dma_state_next;
reg [7:0] burst_counter_reg, burst_counter_next;
reg [MEM_WIDTH-1:0] addr_reg, addr_next;
reg [MEM_WIDTH-1:0] base_addr_reg, base_addr_next;
reg dma_req_reg, dma_req_next;
reg [MEM_WIDTH-1:0] dma_addr_reg, dma_addr_next;
reg txd_reg, txd_next;
reg tx_fifo_empty_reg, tx_fifo_empty_next;
reg [7:0] data_segment [0:3];
reg [7:0] data_segment_reg [0:3];
reg [7:0] data_segment_next [0:3];

// 优化后的数据重对齐逻辑：使用casez和范围检查简化比较链
always @(*) begin
    dma_state_next       = dma_state_reg;
    burst_counter_next   = burst_counter_reg;
    addr_next            = addr_reg;
    base_addr_next       = base_addr_reg;
    dma_req_next         = dma_req_reg;
    dma_addr_next        = dma_addr_reg;
    txd_next             = txd_reg;
    tx_fifo_empty_next   = tx_fifo_empty_reg;
    data_segment_next[0] = data_segment_reg[0];
    data_segment_next[1] = data_segment_reg[1];
    data_segment_next[2] = data_segment_reg[2];
    data_segment_next[3] = data_segment_reg[3];

    // 优化数据重对齐：用casez和范围覆盖
    casez (addr_reg[1:0])
        2'b00: data_segment_next[0] = dma_data[31:24];
        2'b01: data_segment_next[0] = dma_data[23:16];
        2'b10: data_segment_next[0] = dma_data[15:8];
        default: data_segment_next[0] = dma_data[7:0];
    endcase

    // 优化DMA状态机比较链
    if (dma_mode[0]) begin : DMA_SEND_BLOCK
        case (dma_state_reg)
            DMA_IDLE: begin
                if (tx_fifo_empty_reg) begin
                    dma_state_next     = DMA_REQ;
                    addr_next          = base_addr_reg;
                    dma_req_next       = 1'b1;
                end
            end
            DMA_REQ: begin
                if (dma_ack) begin
                    dma_req_next       = 1'b0;
                    dma_state_next     = DMA_XFER;
                    burst_counter_next = 8'd0;
                end
            end
            DMA_XFER: begin
                txd_next             = data_segment_reg[0][7];
                burst_counter_next   = burst_counter_reg + 8'd1;
                // 优化比较链为范围比较
                if (burst_counter_reg >= (BURST_LEN-1)) begin
                    dma_state_next = DMA_LAST;
                end
            end
            DMA_LAST: begin
                dma_state_next       = DMA_IDLE;
                tx_fifo_empty_next   = 1'b0;
            end
            default: dma_state_next  = DMA_IDLE;
        endcase
    end
end

// 时序逻辑
always @(posedge clk or posedge rst) begin
    if (rst) begin
        dma_state_reg       <= DMA_IDLE;
        burst_counter_reg   <= 8'd0;
        addr_reg            <= {MEM_WIDTH{1'b0}};
        base_addr_reg       <= {MEM_WIDTH{1'b0}};
        dma_req_reg         <= 1'b0;
        dma_addr_reg        <= {MEM_WIDTH{1'b0}};
        txd_reg             <= 1'b1;
        tx_fifo_empty_reg   <= 1'b1;
        data_segment_reg[0] <= 8'd0;
        data_segment_reg[1] <= 8'd0;
        data_segment_reg[2] <= 8'd0;
        data_segment_reg[3] <= 8'd0;
    end else begin
        dma_state_reg       <= dma_state_next;
        burst_counter_reg   <= burst_counter_next;
        addr_reg            <= addr_next;
        base_addr_reg       <= base_addr_next;
        dma_req_reg         <= dma_req_next;
        dma_addr_reg        <= dma_addr_next;
        txd_reg             <= txd_next;
        tx_fifo_empty_reg   <= tx_fifo_empty_next;
        data_segment_reg[0] <= data_segment_next[0];
        data_segment_reg[1] <= data_segment_next[1];
        data_segment_reg[2] <= data_segment_next[2];
        data_segment_reg[3] <= data_segment_next[3];
    end
end

// 输出信号赋值
always @(*) begin
    dma_req   = dma_req_reg;
    dma_addr  = dma_addr_reg;
    txd       = txd_reg;
end

endmodule