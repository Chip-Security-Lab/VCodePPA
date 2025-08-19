module SPI_Interrupt #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 4
)(
    input clk, rst_n,
    // SPI接口
    output sclk, mosi, 
    input miso,
    output reg cs_n,
    // 寄存器接口
    input [DATA_WIDTH-1:0] tx_data,
    output [DATA_WIDTH-1:0] rx_data,
    input wr_en, rd_en,
    // 中断信号
    output reg tx_empty_irq,
    output reg rx_full_irq,
    output reg transfer_done_irq
);

reg [DATA_WIDTH-1:0] tx_fifo [0:FIFO_DEPTH-1];
reg [DATA_WIDTH-1:0] rx_fifo [0:FIFO_DEPTH-1];
reg [1:0] tx_wr_ptr, tx_rd_ptr;
reg [1:0] rx_wr_ptr, rx_rd_ptr;
reg [3:0] ctrl_reg; // [IE_TX, IE_RX, IE_DONE, MODE]
reg done_pulse; // 添加完成脉冲信号
reg [$clog2(DATA_WIDTH):0] bit_cnt; // 添加位计数器

// 添加FIFO状态信号
wire fifo_full = ((rx_wr_ptr + 1) % FIFO_DEPTH == rx_rd_ptr);
wire fifo_empty = (tx_wr_ptr == tx_rd_ptr);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_empty_irq <= 0;
        rx_full_irq <= 0;
        transfer_done_irq <= 0;
        done_pulse <= 0;
    end 
    else begin
        // 中断生成逻辑
        tx_empty_irq <= (tx_wr_ptr == tx_rd_ptr) & ctrl_reg[3];
        rx_full_irq <= ((rx_wr_ptr + 1) % FIFO_DEPTH == rx_rd_ptr) & ctrl_reg[2];
        transfer_done_irq <= done_pulse & ctrl_reg[1];
    end
end

// FIFO控制逻辑
always @(posedge clk) begin
    if (wr_en && !fifo_full) begin
        tx_fifo[tx_wr_ptr] <= tx_data;
        tx_wr_ptr <= tx_wr_ptr + 1;
    end
    if (rd_en && !fifo_empty) begin
        rx_rd_ptr <= rx_rd_ptr + 1;
    end
end

// SPI状态机
reg [2:0] state;
localparam IDLE = 0, TRANSFER = 1, DONE = 2;
always @(posedge clk) begin
    case(state)
    IDLE: 
        if (!fifo_empty) begin
            state <= TRANSFER;
            bit_cnt <= 0;
            cs_n <= 1'b0;
        end
    TRANSFER:
        if (bit_cnt == DATA_WIDTH) begin
            state <= DONE;
            done_pulse <= 1'b1;
            cs_n <= 1'b1;
        end else begin
            bit_cnt <= bit_cnt + 1;
        end
    DONE: begin
        state <= IDLE;
        done_pulse <= 1'b0;
    end
    endcase
end

// 简单的SPI信号生成
reg sclk_int;
always @(posedge clk) begin
    if (state == TRANSFER) 
        sclk_int <= ~sclk_int;
    else
        sclk_int <= 1'b0;
end

assign sclk = sclk_int;
assign mosi = (state == TRANSFER) ? tx_fifo[tx_rd_ptr][DATA_WIDTH-1-bit_cnt] : 1'b0;
assign rx_data = rx_fifo[rx_rd_ptr];
endmodule