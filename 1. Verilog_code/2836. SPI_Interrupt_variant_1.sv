//SystemVerilog
// Top module with parallel prefix 4-bit subtractor
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
reg done_pulse; // 完成脉冲信号
reg [$clog2(DATA_WIDTH):0] bit_cnt; // 位计数器

// FIFO状态信号
wire [1:0] rx_wr_ptr_next;
wire [1:0] tx_wr_ptr_next;
wire [1:0] rx_ptr_sub;
wire [1:0] tx_ptr_sub;
wire rx_fifo_full;
wire tx_fifo_empty;

// 使用并行前缀减法器计算 4 位 FIFO 指针差值
ParallelPrefixSubtractor4 rx_ptr_subtractor (
    .a(rx_wr_ptr + 1'b1),
    .b(rx_rd_ptr),
    .diff(rx_ptr_sub)
);

ParallelPrefixSubtractor4 tx_ptr_subtractor (
    .a(tx_wr_ptr),
    .b(tx_rd_ptr),
    .diff(tx_ptr_sub)
);

assign rx_fifo_full = (rx_ptr_sub == 2'd0);
assign tx_fifo_empty = (tx_ptr_sub == 2'd0);

// 中断生成逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_empty_irq <= 1'b0;
        rx_full_irq <= 1'b0;
        transfer_done_irq <= 1'b0;
        done_pulse <= 1'b0;
    end 
    else begin
        tx_empty_irq <= tx_fifo_empty & ctrl_reg[3];
        rx_full_irq <= rx_fifo_full & ctrl_reg[2];
        transfer_done_irq <= done_pulse & ctrl_reg[1];
    end
end

// FIFO控制逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_wr_ptr <= 2'd0;
        tx_rd_ptr <= 2'd0;
        rx_wr_ptr <= 2'd0;
        rx_rd_ptr <= 2'd0;
    end else begin
        if (wr_en && !rx_fifo_full) begin
            tx_fifo[tx_wr_ptr] <= tx_data;
            tx_wr_ptr <= tx_wr_ptr + 1'b1;
        end
        if (rd_en && !tx_fifo_empty) begin
            rx_rd_ptr <= rx_rd_ptr + 1'b1;
        end
    end
end

// SPI状态机
reg [2:0] spi_state;
localparam IDLE = 3'd0, TRANSFER = 3'd1, DONE = 3'd2;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        spi_state <= IDLE;
        bit_cnt <= 0;
        cs_n <= 1'b1;
        done_pulse <= 1'b0;
    end else begin
        case(spi_state)
        IDLE: 
            if (!tx_fifo_empty) begin
                spi_state <= TRANSFER;
                bit_cnt <= 0;
                cs_n <= 1'b0;
            end
        TRANSFER:
            if (bit_cnt == DATA_WIDTH) begin
                spi_state <= DONE;
                done_pulse <= 1'b1;
                cs_n <= 1'b1;
            end else begin
                bit_cnt <= bit_cnt + 1'b1;
            end
        DONE: begin
            spi_state <= IDLE;
            done_pulse <= 1'b0;
        end
        endcase
    end
end

// SPI信号生成
reg sclk_int;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sclk_int <= 1'b0;
    end else begin
        if (spi_state == TRANSFER) 
            sclk_int <= ~sclk_int;
        else
            sclk_int <= 1'b0;
    end
end

assign sclk = sclk_int;
assign mosi = (spi_state == TRANSFER) ? tx_fifo[tx_rd_ptr][DATA_WIDTH-1-bit_cnt] : 1'b0;
assign rx_data = rx_fifo[rx_rd_ptr];

endmodule

// 4位并行前缀减法器（Kogge-Stone结构）
module ParallelPrefixSubtractor4 (
    input  [1:0] a,
    input  [1:0] b,
    output [1:0] diff
);
    wire [1:0] b_inv;
    wire [1:0] g, p;
    wire [2:0] c; // c[0] is cin, c[2] is cout
    assign b_inv = ~b;
    assign c[0] = 1'b1; // 减法的cin=1

    // 级联生成G/P信号
    assign g[0] = a[0] & b_inv[0];
    assign p[0] = a[0] ^ b_inv[0];

    assign g[1] = a[1] & b_inv[1];
    assign p[1] = a[1] ^ b_inv[1];

    // 前缀进位
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & c[1]);

    assign diff[0] = p[0] ^ c[0];
    assign diff[1] = p[1] ^ c[1];
endmodule