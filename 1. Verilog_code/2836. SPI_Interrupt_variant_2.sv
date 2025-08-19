//SystemVerilog
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

// FIFO寄存器及指针
reg [DATA_WIDTH-1:0] tx_fifo [0:FIFO_DEPTH-1];
reg [DATA_WIDTH-1:0] rx_fifo [0:FIFO_DEPTH-1];
reg [1:0] tx_wr_ptr, tx_rd_ptr;
reg [1:0] rx_wr_ptr, rx_rd_ptr;
reg [3:0] ctrl_reg; // [IE_TX, IE_RX, IE_DONE, MODE]

// FIFO状态信号
wire fifo_full_stage1, fifo_full_stage2;
wire fifo_empty_stage1, fifo_empty_stage2;
reg tmp_fifo_full;
reg tmp_fifo_empty;

// 两级流水线：FIFO状态信号
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tmp_fifo_full <= 1'b0;
        tmp_fifo_empty <= 1'b1;
    end else begin
        tmp_fifo_full <= (((rx_wr_ptr + 1) % FIFO_DEPTH) == rx_rd_ptr);
        tmp_fifo_empty <= (tx_wr_ptr == tx_rd_ptr);
    end
end
assign fifo_full_stage1 = tmp_fifo_full;
assign fifo_empty_stage1 = tmp_fifo_empty;
assign fifo_full_stage2 = fifo_full_stage1;
assign fifo_empty_stage2 = fifo_empty_stage1;

// 中断信号流水线级
reg tx_empty_irq_stage1, rx_full_irq_stage1, transfer_done_irq_stage1;
reg done_pulse_stage1, done_pulse_stage2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_empty_irq_stage1 <= 1'b0;
        rx_full_irq_stage1 <= 1'b0;
        transfer_done_irq_stage1 <= 1'b0;
        done_pulse_stage1 <= 1'b0;
        done_pulse_stage2 <= 1'b0;
    end 
    else begin
        // tx_empty_irq
        if ((tx_wr_ptr == tx_rd_ptr) & ctrl_reg[3])
            tx_empty_irq_stage1 <= 1'b1;
        else
            tx_empty_irq_stage1 <= 1'b0;

        // rx_full_irq
        if ((((rx_wr_ptr + 1) % FIFO_DEPTH) == rx_rd_ptr) & ctrl_reg[2])
            rx_full_irq_stage1 <= 1'b1;
        else
            rx_full_irq_stage1 <= 1'b0;

        // transfer_done_irq
        if (done_pulse_stage2 & ctrl_reg[1])
            transfer_done_irq_stage1 <= 1'b1;
        else
            transfer_done_irq_stage1 <= 1'b0;

        // done_pulse流水线
        done_pulse_stage2 <= done_pulse_stage1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_empty_irq <= 1'b0;
        rx_full_irq <= 1'b0;
        transfer_done_irq <= 1'b0;
    end else begin
        tx_empty_irq <= tx_empty_irq_stage1;
        rx_full_irq <= rx_full_irq_stage1;
        transfer_done_irq <= transfer_done_irq_stage1;
    end
end

// FIFO控制逻辑流水线
reg wr_fifo_stage1, wr_fifo_stage2;
reg rd_fifo_stage1, rd_fifo_stage2;
reg [DATA_WIDTH-1:0] tx_data_stage1, tx_data_stage2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_fifo_stage1 <= 1'b0;
        wr_fifo_stage2 <= 1'b0;
        rd_fifo_stage1 <= 1'b0;
        rd_fifo_stage2 <= 1'b0;
        tx_data_stage1 <= {DATA_WIDTH{1'b0}};
        tx_data_stage2 <= {DATA_WIDTH{1'b0}};
    end else begin
        wr_fifo_stage1 <= wr_en & !fifo_full_stage2;
        wr_fifo_stage2 <= wr_fifo_stage1;
        tx_data_stage1 <= tx_data;
        tx_data_stage2 <= tx_data_stage1;
        rd_fifo_stage1 <= rd_en & !fifo_empty_stage2;
        rd_fifo_stage2 <= rd_fifo_stage1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_wr_ptr <= 2'b0;
        tx_rd_ptr <= 2'b0;
        rx_wr_ptr <= 2'b0;
        rx_rd_ptr <= 2'b0;
    end else begin
        if (wr_fifo_stage2) begin
            tx_fifo[tx_wr_ptr] <= tx_data_stage2;
            tx_wr_ptr <= tx_wr_ptr + 1;
        end
        if (rd_fifo_stage2) begin
            rx_rd_ptr <= rx_rd_ptr + 1;
        end
    end
end

// --- SPI状态机流水线优化 ---
// 拆分为三流水线级：状态转移、计数/CS信号、完成脉冲生成与采样

reg [2:0] state_stage1, state_stage2, state_stage3;
reg [2:0] state_next_stage1, state_next_stage2;
reg [$clog2(DATA_WIDTH):0] bit_cnt_stage1, bit_cnt_stage2, bit_cnt_stage3;
reg cs_n_stage1, cs_n_stage2, cs_n_stage3;
reg done_pulse_int_stage1, done_pulse_int_stage2, done_pulse_int_stage3;

localparam IDLE = 0, TRANSFER = 1, DONE = 2;

// 状态转移流水线级1
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_stage1 <= IDLE;
        bit_cnt_stage1 <= 0;
        cs_n_stage1 <= 1'b1;
        done_pulse_int_stage1 <= 1'b0;
    end else begin
        case (state_stage1)
            IDLE: begin
                if (!fifo_empty_stage2) begin
                    state_next_stage1 <= TRANSFER;
                    bit_cnt_stage1 <= 0;
                    cs_n_stage1 <= 1'b0;
                    done_pulse_int_stage1 <= 1'b0;
                end else begin
                    state_next_stage1 <= IDLE;
                    cs_n_stage1 <= 1'b1;
                    done_pulse_int_stage1 <= 1'b0;
                end
            end
            TRANSFER: begin
                if (bit_cnt_stage1 == DATA_WIDTH) begin
                    state_next_stage1 <= DONE;
                    cs_n_stage1 <= 1'b1;
                    done_pulse_int_stage1 <= 1'b1;
                end else begin
                    state_next_stage1 <= TRANSFER;
                    cs_n_stage1 <= 1'b0;
                    done_pulse_int_stage1 <= 1'b0;
                end
            end
            DONE: begin
                state_next_stage1 <= IDLE;
                cs_n_stage1 <= 1'b1;
                done_pulse_int_stage1 <= 1'b0;
            end
            default: begin
                state_next_stage1 <= IDLE;
                cs_n_stage1 <= 1'b1;
                done_pulse_int_stage1 <= 1'b0;
            end
        endcase
        state_stage1 <= state_next_stage1;
    end
end

// 状态转移流水线级2
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_stage2 <= IDLE;
        bit_cnt_stage2 <= 0;
        cs_n_stage2 <= 1'b1;
        done_pulse_int_stage2 <= 1'b0;
    end else begin
        state_stage2 <= state_stage1;
        cs_n_stage2 <= cs_n_stage1;
        done_pulse_int_stage2 <= done_pulse_int_stage1;
        if (state_stage1 == TRANSFER && bit_cnt_stage1 != DATA_WIDTH)
            bit_cnt_stage2 <= bit_cnt_stage1 + 1;
        else if (state_stage1 == IDLE)
            bit_cnt_stage2 <= 0;
        else
            bit_cnt_stage2 <= bit_cnt_stage1;
    end
end

// 状态转移流水线级3
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_stage3 <= IDLE;
        bit_cnt_stage3 <= 0;
        cs_n_stage3 <= 1'b1;
        done_pulse_int_stage3 <= 1'b0;
    end else begin
        state_stage3 <= state_stage2;
        bit_cnt_stage3 <= bit_cnt_stage2;
        cs_n_stage3 <= cs_n_stage2;
        done_pulse_int_stage3 <= done_pulse_int_stage2;
    end
end

// 更新CS信号和完成脉冲信号
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cs_n <= 1'b1;
        done_pulse_stage1 <= 1'b0;
    end else begin
        cs_n <= cs_n_stage3;
        done_pulse_stage1 <= done_pulse_int_stage3;
    end
end

// --- SPI信号生成流水线优化 ---
reg sclk_toggle_stage1, sclk_toggle_stage2, sclk_int_stage1, sclk_int_stage2, sclk_int_stage3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sclk_toggle_stage1 <= 1'b0;
        sclk_int_stage1 <= 1'b0;
    end else begin
        if (state_stage1 == TRANSFER)
            sclk_toggle_stage1 <= ~sclk_toggle_stage1;
        else
            sclk_toggle_stage1 <= 1'b0;
        sclk_int_stage1 <= sclk_toggle_stage1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sclk_int_stage2 <= 1'b0;
        sclk_int_stage3 <= 1'b0;
    end else begin
        sclk_int_stage2 <= sclk_int_stage1;
        sclk_int_stage3 <= sclk_int_stage2;
    end
end

assign sclk = sclk_int_stage3;

// --- MOSI信号流水线优化 ---
reg mosi_reg_stage1, mosi_reg_stage2, mosi_reg_stage3;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mosi_reg_stage1 <= 1'b0;
        mosi_reg_stage2 <= 1'b0;
        mosi_reg_stage3 <= 1'b0;
    end else begin
        if (state_stage1 == TRANSFER)
            mosi_reg_stage1 <= tx_fifo[tx_rd_ptr][DATA_WIDTH-1-bit_cnt_stage1];
        else
            mosi_reg_stage1 <= 1'b0;
        mosi_reg_stage2 <= mosi_reg_stage1;
        mosi_reg_stage3 <= mosi_reg_stage2;
    end
end
assign mosi = mosi_reg_stage3;

// --- RX_DATA信号流水线优化 ---
reg [DATA_WIDTH-1:0] rx_data_reg_stage1, rx_data_reg_stage2;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_data_reg_stage1 <= {DATA_WIDTH{1'b0}};
        rx_data_reg_stage2 <= {DATA_WIDTH{1'b0}};
    end else begin
        rx_data_reg_stage1 <= rx_fifo[rx_rd_ptr];
        rx_data_reg_stage2 <= rx_data_reg_stage1;
    end
end
assign rx_data = rx_data_reg_stage2;

endmodule