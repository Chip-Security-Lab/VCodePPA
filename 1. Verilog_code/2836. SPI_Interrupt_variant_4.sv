//SystemVerilog
module SPI_Interrupt #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 4
)(
    input wire clk, 
    input wire rst_n,
    // SPI接口
    output wire sclk, 
    output wire mosi, 
    input wire miso,
    output reg cs_n,
    // 寄存器接口
    input wire [DATA_WIDTH-1:0] tx_data,
    output wire [DATA_WIDTH-1:0] rx_data,
    input wire wr_en, 
    input wire rd_en,
    // 中断信号
    output reg tx_empty_irq,
    output reg rx_full_irq,
    output reg transfer_done_irq
);

    // ===================== FIFO状态与控制 ===================== //
    reg [DATA_WIDTH-1:0] tx_fifo [0:FIFO_DEPTH-1];
    reg [DATA_WIDTH-1:0] rx_fifo [0:FIFO_DEPTH-1];
    reg [1:0] tx_wr_ptr, tx_rd_ptr;
    reg [1:0] rx_wr_ptr, rx_rd_ptr;

    wire tx_fifo_empty, tx_fifo_full;
    wire rx_fifo_empty, rx_fifo_full;

    assign tx_fifo_empty = (tx_wr_ptr == tx_rd_ptr);
    assign tx_fifo_full  = ((tx_wr_ptr + 1) % FIFO_DEPTH == tx_rd_ptr);

    assign rx_fifo_empty = (rx_wr_ptr == rx_rd_ptr);
    assign rx_fifo_full  = ((rx_wr_ptr + 1) % FIFO_DEPTH == rx_rd_ptr);

    // ===================== 控制与中断寄存器 ===================== //
    reg [3:0] ctrl_reg; // [IE_TX, IE_RX, IE_DONE, MODE]
    reg transfer_done_pulse_stage1, transfer_done_pulse_stage2;

    // ===================== Pipeline Stage 1: 寄存器写入FIFO ===================== //
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_wr_ptr <= 2'b0;
        end else if (wr_en && !tx_fifo_full) begin
            tx_fifo[tx_wr_ptr] <= tx_data;
            tx_wr_ptr <= tx_wr_ptr + 1'b1;
        end
    end

    // ===================== Pipeline Stage 2: SPI传输控制 ===================== //
    // 状态机与分阶段信号
    reg [2:0] spi_state, spi_state_next;
    localparam ST_IDLE      = 3'd0,
               ST_LOAD      = 3'd1,
               ST_TRANSFER  = 3'd2,
               ST_DONE      = 3'd3;

    reg [$clog2(DATA_WIDTH):0] bit_counter_stage1, bit_counter_stage2;
    reg [DATA_WIDTH-1:0] tx_shift_reg_stage1, tx_shift_reg_stage2;
    reg [DATA_WIDTH-1:0] rx_shift_reg_stage1, rx_shift_reg_stage2;
    reg [1:0] tx_rd_ptr_stage1, tx_rd_ptr_stage2;
    reg sclk_gen_stage1, sclk_gen_stage2;
    reg cs_n_stage1, cs_n_stage2;
    reg sclk_int;
    reg mosi_reg;

    // SPI 状态机: Stage1 (寄存器切分) - 扁平化if-else
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_state          <= ST_IDLE;
            bit_counter_stage1 <= 0;
            tx_shift_reg_stage1<= 0;
            rx_shift_reg_stage1<= 0;
            tx_rd_ptr_stage1   <= 0;
            cs_n_stage1        <= 1'b1;
            sclk_gen_stage1    <= 1'b0;
        end else if (spi_state == ST_IDLE && !tx_fifo_empty) begin
            spi_state          <= ST_LOAD;
            tx_rd_ptr_stage1   <= tx_rd_ptr;
            cs_n_stage1        <= 1'b1;
            sclk_gen_stage1    <= 1'b0;
        end else if (spi_state == ST_IDLE && tx_fifo_empty) begin
            cs_n_stage1        <= 1'b1;
            sclk_gen_stage1    <= 1'b0;
        end else if (spi_state == ST_LOAD) begin
            tx_shift_reg_stage1 <= tx_fifo[tx_rd_ptr_stage1];
            rx_shift_reg_stage1 <= 0;
            bit_counter_stage1  <= 0;
            cs_n_stage1         <= 1'b0;
            spi_state           <= ST_TRANSFER;
        end else if (spi_state == ST_TRANSFER && bit_counter_stage1 == DATA_WIDTH) begin
            spi_state           <= ST_DONE;
            cs_n_stage1         <= 1'b1;
            sclk_gen_stage1     <= 1'b0;
        end else if (spi_state == ST_TRANSFER && bit_counter_stage1 != DATA_WIDTH) begin
            bit_counter_stage1  <= bit_counter_stage1 + 1'b1;
            cs_n_stage1         <= 1'b0;
            sclk_gen_stage1     <= ~sclk_gen_stage1;
        end else if (spi_state == ST_DONE) begin
            spi_state <= ST_IDLE;
        end else begin
            spi_state          <= ST_IDLE;
            cs_n_stage1        <= 1'b1;
            sclk_gen_stage1    <= 1'b0;
        end
    end

    // SPI 状态机: Stage2 (流水线寄存器)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift_reg_stage2    <= 0;
            rx_shift_reg_stage2    <= 0;
            bit_counter_stage2     <= 0;
            tx_rd_ptr_stage2       <= 0;
            sclk_gen_stage2        <= 0;
            cs_n_stage2            <= 1'b1;
            transfer_done_pulse_stage1 <= 1'b0;
        end else begin
            tx_shift_reg_stage2    <= tx_shift_reg_stage1;
            rx_shift_reg_stage2    <= rx_shift_reg_stage1;
            bit_counter_stage2     <= bit_counter_stage1;
            tx_rd_ptr_stage2       <= tx_rd_ptr_stage1;
            sclk_gen_stage2        <= sclk_gen_stage1;
            cs_n_stage2            <= cs_n_stage1;
            transfer_done_pulse_stage1 <= (spi_state == ST_DONE) ? 1'b1 : 1'b0;
        end
    end

    // SPI SCLK/CS输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_int <= 1'b0;
            cs_n     <= 1'b1;
        end else begin
            sclk_int <= sclk_gen_stage2;
            cs_n     <= cs_n_stage2;
        end
    end
    assign sclk = sclk_int;

    // MOSI输出 (流水线寄存器) - 扁平化if-else
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mosi_reg <= 1'b0;
        end else if (spi_state == ST_TRANSFER) begin
            mosi_reg <= tx_shift_reg_stage2[DATA_WIDTH-1 - bit_counter_stage2];
        end else if (spi_state != ST_TRANSFER) begin
            mosi_reg <= 1'b0;
        end
    end
    assign mosi = mosi_reg;

    // ===================== Pipeline Stage 3: SPI接收与FIFO写入 ===================== //
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_wr_ptr <= 2'b0;
            tx_rd_ptr <= 2'b0;
        end else if (transfer_done_pulse_stage1 && !rx_fifo_full) begin
            rx_fifo[rx_wr_ptr] <= rx_shift_reg_stage2;
            rx_wr_ptr <= rx_wr_ptr + 1'b1;
            tx_rd_ptr <= tx_rd_ptr + 1'b1;
            if (rd_en && !rx_fifo_empty) begin
                rx_rd_ptr <= rx_rd_ptr + 1'b1;
            end
        end else if (rd_en && !rx_fifo_empty) begin
            rx_rd_ptr <= rx_rd_ptr + 1'b1;
        end
    end

    // ===================== Transfer Done 脉冲同步 ===================== //
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            transfer_done_pulse_stage2 <= 1'b0;
        else
            transfer_done_pulse_stage2 <= transfer_done_pulse_stage1;
    end

    // ===================== 中断生成逻辑 ===================== //
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_empty_irq       <= 1'b0;
            rx_full_irq        <= 1'b0;
            transfer_done_irq  <= 1'b0;
        end else begin
            tx_empty_irq       <= (tx_fifo_empty && ctrl_reg[3]);
            rx_full_irq        <= (rx_fifo_full  && ctrl_reg[2]);
            transfer_done_irq  <= (transfer_done_pulse_stage2 && ctrl_reg[1]);
        end
    end

    // ===================== SPI输入采样 (接收数据) - 扁平化if-else ===================== //
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_shift_reg_stage1 <= 0;
        end else if ((spi_state == ST_TRANSFER) && sclk_gen_stage1) begin
            rx_shift_reg_stage1 <= {rx_shift_reg_stage1[DATA_WIDTH-2:0], miso};
        end
    end

    // ===================== 输出数据 ===================== //
    assign rx_data = rx_fifo[rx_rd_ptr];

endmodule