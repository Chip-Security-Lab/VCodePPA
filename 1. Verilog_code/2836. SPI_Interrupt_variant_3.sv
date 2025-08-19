//SystemVerilog
`timescale 1ns/1ps
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

// FIFO存储和指针
reg [DATA_WIDTH-1:0] tx_fifo [0:FIFO_DEPTH-1];
reg [DATA_WIDTH-1:0] rx_fifo [0:FIFO_DEPTH-1];
reg [1:0] tx_wr_ptr, tx_rd_ptr;
reg [1:0] rx_wr_ptr, rx_rd_ptr;

// 控制和状态寄存器
reg [3:0] ctrl_reg; // [IE_TX, IE_RX, IE_DONE, MODE]
reg done_pulse; 
reg [$clog2(DATA_WIDTH):0] bit_cnt;

// FIFO状态信号（组合逻辑）
wire fifo_full_next, fifo_empty_next;
assign fifo_full_next  = ((rx_wr_ptr + 1) % FIFO_DEPTH == rx_rd_ptr);
assign fifo_empty_next = (tx_wr_ptr == tx_rd_ptr);

// --- 前向重定时变换开始 ---
// 原始寄存器在输入wr_en/tx_data/rd_en后立即采样，这里将寄存器移到组合逻辑后面

// 组合逻辑：采样输入，产生FIFO写入请求
wire wr_en_valid;
assign wr_en_valid = wr_en && !fifo_full_next;

wire rd_en_valid;
assign rd_en_valid = rd_en && !fifo_empty_next;

// 前向重定时：将tx_data输入数据、wr_en控制信号先通过组合逻辑再进入寄存器
reg [DATA_WIDTH-1:0] tx_data_reg;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        tx_data_reg <= {DATA_WIDTH{1'b0}};
    else if (wr_en_valid)
        tx_data_reg <= tx_data;
end

// tx_fifo写操作和写指针
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_wr_ptr <= 2'd0;
    end else if (wr_en_valid) begin
        tx_fifo[tx_wr_ptr] <= tx_data_reg;
        tx_wr_ptr <= tx_wr_ptr + 1'b1;
    end
end

// rx_fifo读指针
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_rd_ptr <= 2'd0;
    end else if (rd_en_valid) begin
        rx_rd_ptr <= rx_rd_ptr + 1'b1;
    end
end
// --- 前向重定时变换结束 ---

// SPI状态机（独热编码）
reg [3:0] spi_state_onehot;
localparam SPI_IDLE     = 4'b0001;
localparam SPI_TRANSFER = 4'b0010;
localparam SPI_DONE     = 4'b0100;
localparam SPI_UNUSED   = 4'b1000; // 未用状态，保留

wire is_idle     = spi_state_onehot[0];
wire is_transfer = spi_state_onehot[1];
wire is_done     = spi_state_onehot[2];
// spi_state_onehot[3]为未用

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        spi_state_onehot <= SPI_IDLE;
        bit_cnt <= 0;
        cs_n <= 1'b1;
        done_pulse <= 1'b0;
    end else begin
        case (1'b1)
        is_idle: begin
            done_pulse <= 1'b0;
            if (!fifo_empty_next) begin
                spi_state_onehot <= SPI_TRANSFER;
                bit_cnt <= 0;
                cs_n <= 1'b0;
            end else begin
                spi_state_onehot <= SPI_IDLE;
                cs_n <= 1'b1;
            end
        end
        is_transfer: begin
            if (bit_cnt == DATA_WIDTH) begin
                spi_state_onehot <= SPI_DONE;
                done_pulse <= 1'b1;
                cs_n <= 1'b1;
            end else begin
                bit_cnt <= bit_cnt + 1'b1;
                spi_state_onehot <= SPI_TRANSFER;
                cs_n <= 1'b0;
            end
        end
        is_done: begin
            spi_state_onehot <= SPI_IDLE;
            done_pulse <= 1'b0;
            cs_n <= 1'b1;
        end
        default: begin
            spi_state_onehot <= SPI_IDLE;
            done_pulse <= 1'b0;
            cs_n <= 1'b1;
        end
        endcase
    end
end

// tx_rd_ptr 在每次传输完成后自增
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_rd_ptr <= 2'd0;
    end else if (is_done) begin
        if (!fifo_empty_next)
            tx_rd_ptr <= tx_rd_ptr + 1'b1;
    end
end

// rx_fifo写指针和采样（假设收到数据时采样）
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_wr_ptr <= 2'd0;
    end else if (is_done) begin
        rx_fifo[rx_wr_ptr] <= {DATA_WIDTH{1'b0}}; // 可根据miso采集实际数据
        rx_wr_ptr <= rx_wr_ptr + 1'b1;
    end
end

// 中断逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_empty_irq <= 1'b0;
        rx_full_irq <= 1'b0;
        transfer_done_irq <= 1'b0;
    end else begin
        tx_empty_irq       <= (tx_wr_ptr == tx_rd_ptr) & ctrl_reg[3];
        rx_full_irq        <= ((rx_wr_ptr + 1) % FIFO_DEPTH == rx_rd_ptr) & ctrl_reg[2];
        transfer_done_irq  <= done_pulse & ctrl_reg[1];
    end
end

// SPI信号生成
reg sclk_int;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sclk_int <= 1'b0;
    end else if (is_transfer) begin
        sclk_int <= ~sclk_int;
    end else begin
        sclk_int <= 1'b0;
    end
end

assign sclk = sclk_int;
assign mosi = (is_transfer) ? tx_fifo[tx_rd_ptr][DATA_WIDTH-1-bit_cnt] : 1'b0;
assign rx_data = rx_fifo[rx_rd_ptr];

endmodule