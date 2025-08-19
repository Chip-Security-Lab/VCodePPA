//SystemVerilog
module spi_master_fifo #(
    parameter FIFO_DEPTH = 16,
    parameter DATA_WIDTH = 8
)(
    input  wire                      clk,
    input  wire                      rst_n,

    // FIFO interface
    input  wire [DATA_WIDTH-1:0]     tx_data,
    input  wire                      tx_write,
    output wire                      tx_full,
    output wire [DATA_WIDTH-1:0]     rx_data,
    output wire                      rx_valid,
    input  wire                      rx_read,
    output wire                      rx_empty,

    // SPI interface
    output reg                       sclk,
    output reg                       cs_n,
    output wire                      mosi,
    input  wire                      miso
);

    // ==============================
    // FIFO Control and Pipeline Stage
    // ==============================

    // Write FIFO for TX path
    reg [DATA_WIDTH-1:0]        tx_fifo_mem [0:FIFO_DEPTH-1];
    reg [$clog2(FIFO_DEPTH):0]  tx_fifo_count_stage1;
    reg [$clog2(FIFO_DEPTH)-1:0] tx_fifo_rd_ptr_stage1, tx_fifo_wr_ptr_stage1;
    wire                        tx_fifo_write_en;
    wire                        tx_fifo_read_en;
    wire                        tx_fifo_full_stage1;
    wire                        tx_fifo_empty_stage1;
    reg  [DATA_WIDTH-1:0]       tx_fifo_dout_stage1;

    // Read FIFO for RX path
    reg [DATA_WIDTH-1:0]        rx_fifo_mem [0:FIFO_DEPTH-1];
    reg [$clog2(FIFO_DEPTH):0]  rx_fifo_count_stage1;
    reg [$clog2(FIFO_DEPTH)-1:0] rx_fifo_rd_ptr_stage1, rx_fifo_wr_ptr_stage1;
    wire                        rx_fifo_write_en;
    wire                        rx_fifo_read_en;
    wire                        rx_fifo_full_stage1;
    wire                        rx_fifo_empty_stage1;
    reg  [DATA_WIDTH-1:0]       rx_fifo_dout_stage1;

    // FIFO write/read enables
    assign tx_fifo_write_en = tx_write && !tx_fifo_full_stage1;
    assign tx_fifo_read_en  = spi_tx_load_en;
    assign rx_fifo_write_en = spi_rx_store_en;
    assign rx_fifo_read_en  = rx_read && !rx_fifo_empty_stage1;

    // FIFO status signals
    assign tx_fifo_full_stage1  = (tx_fifo_count_stage1 == FIFO_DEPTH[$clog2(FIFO_DEPTH):0]);
    assign tx_fifo_empty_stage1 = (tx_fifo_count_stage1 == {($clog2(FIFO_DEPTH)+1){1'b0}});
    assign rx_fifo_full_stage1  = (rx_fifo_count_stage1 == FIFO_DEPTH[$clog2(FIFO_DEPTH):0]);
    assign rx_fifo_empty_stage1 = (rx_fifo_count_stage1 == {($clog2(FIFO_DEPTH)+1){1'b0}});

    assign tx_full  = tx_fifo_full_stage1;
    assign rx_empty = rx_fifo_empty_stage1;
    assign rx_valid = !rx_fifo_empty_stage1;

    assign rx_data  = rx_fifo_dout_stage1;

    // TX FIFO write
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_fifo_wr_ptr_stage1 <= {($clog2(FIFO_DEPTH)){1'b0}};
            tx_fifo_count_stage1  <= {($clog2(FIFO_DEPTH)+1){1'b0}};
        end else begin
            if (tx_fifo_write_en) begin
                tx_fifo_mem[tx_fifo_wr_ptr_stage1] <= tx_data;
                tx_fifo_wr_ptr_stage1 <= tx_fifo_wr_ptr_stage1 + 1'b1;
                tx_fifo_count_stage1  <= tx_fifo_count_stage1 + 1'b1;
            end
            if (tx_fifo_read_en && !tx_fifo_empty_stage1) begin
                tx_fifo_rd_ptr_stage1 <= tx_fifo_rd_ptr_stage1 + 1'b1;
                tx_fifo_count_stage1  <= tx_fifo_count_stage1 - 1'b1;
            end
        end
    end

    // TX FIFO output pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            tx_fifo_dout_stage1 <= {DATA_WIDTH{1'b0}};
        else if (!tx_fifo_empty_stage1 && !spi_active_stage1)
            tx_fifo_dout_stage1 <= tx_fifo_mem[tx_fifo_rd_ptr_stage1];
    end

    // RX FIFO write
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_fifo_wr_ptr_stage1 <= {($clog2(FIFO_DEPTH)){1'b0}};
            rx_fifo_count_stage1  <= {($clog2(FIFO_DEPTH)+1){1'b0}};
        end else begin
            if (rx_fifo_write_en) begin
                rx_fifo_mem[rx_fifo_wr_ptr_stage1] <= spi_rx_shift_reg_stage2;
                rx_fifo_wr_ptr_stage1 <= rx_fifo_wr_ptr_stage1 + 1'b1;
                rx_fifo_count_stage1  <= rx_fifo_count_stage1 + 1'b1;
            end
            if (rx_fifo_read_en && !rx_fifo_empty_stage1) begin
                rx_fifo_rd_ptr_stage1 <= rx_fifo_rd_ptr_stage1 + 1'b1;
                rx_fifo_count_stage1  <= rx_fifo_count_stage1 - 1'b1;
            end
        end
    end

    // RX FIFO output pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rx_fifo_dout_stage1 <= {DATA_WIDTH{1'b0}};
        else if (!rx_fifo_empty_stage1)
            rx_fifo_dout_stage1 <= rx_fifo_mem[rx_fifo_rd_ptr_stage1];
    end

    // =====================================
    // SPI Pipeline and Data Flow Structure
    // =====================================

    // SPI pipeline registers
    reg [DATA_WIDTH-1:0]        spi_tx_shift_reg_stage1, spi_tx_shift_reg_stage2;
    reg [DATA_WIDTH-1:0]        spi_rx_shift_reg_stage1, spi_rx_shift_reg_stage2;
    reg [$clog2(DATA_WIDTH):0]  spi_bit_count_stage1,   spi_bit_count_stage2;
    reg                         spi_active_stage1,      spi_active_stage2;
    reg                         spi_tx_load_en,         spi_rx_store_en;
    reg                         sclk_en_stage1,         sclk_en_stage2;

    // SPI Control FSM state
    typedef enum reg [1:0] {IDLE, LOAD, TRANSFER, STORE} spi_fsm_state_t;
    reg [1:0] spi_fsm_state_stage1, spi_fsm_state_stage2;

    // SPI transfer pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_fsm_state_stage1    <= IDLE;
            spi_bit_count_stage1    <= {($clog2(DATA_WIDTH)+1){1'b0}};
            spi_tx_shift_reg_stage1 <= {DATA_WIDTH{1'b0}};
            spi_rx_shift_reg_stage1 <= {DATA_WIDTH{1'b0}};
            spi_active_stage1       <= 1'b0;
            sclk_en_stage1          <= 1'b0;
            spi_tx_load_en          <= 1'b0;
            spi_rx_store_en         <= 1'b0;
            cs_n                    <= 1'b1;
        end else begin
            spi_tx_load_en  <= 1'b0;
            spi_rx_store_en <= 1'b0;
            case (spi_fsm_state_stage1)
                IDLE: begin
                    cs_n         <= 1'b1;
                    sclk_en_stage1 <= 1'b0;
                    if (!tx_fifo_empty_stage1) begin
                        spi_fsm_state_stage1 <= LOAD;
                    end
                end
                LOAD: begin
                    cs_n         <= 1'b0;
                    sclk_en_stage1 <= 1'b1;
                    spi_tx_shift_reg_stage1 <= tx_fifo_dout_stage1;
                    spi_rx_shift_reg_stage1 <= {DATA_WIDTH{1'b0}};
                    spi_bit_count_stage1    <= DATA_WIDTH[$clog2(DATA_WIDTH):0] - 1'b1;
                    spi_active_stage1       <= 1'b1;
                    spi_tx_load_en          <= 1'b1;
                    spi_fsm_state_stage1    <= TRANSFER;
                end
                TRANSFER: begin
                    if (sclk) begin
                        spi_rx_shift_reg_stage1 <= {spi_rx_shift_reg_stage1[DATA_WIDTH-2:0], miso};
                        spi_tx_shift_reg_stage1 <= {spi_tx_shift_reg_stage1[DATA_WIDTH-2:0], 1'b0};
                        if (spi_bit_count_stage1 == 0) begin
                            spi_fsm_state_stage1 <= STORE;
                        end else begin
                            spi_bit_count_stage1 <= spi_bit_count_stage1 - 1'b1;
                        end
                    end
                end
                STORE: begin
                    spi_active_stage1       <= 1'b0;
                    sclk_en_stage1          <= 1'b0;
                    spi_rx_store_en         <= 1'b1;
                    spi_fsm_state_stage1    <= IDLE;
                end
                default: spi_fsm_state_stage1 <= IDLE;
            endcase
        end
    end

    // Pipeline register stage2 for SPI signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_fsm_state_stage2    <= IDLE;
            spi_bit_count_stage2    <= {($clog2(DATA_WIDTH)+1){1'b0}};
            spi_tx_shift_reg_stage2 <= {DATA_WIDTH{1'b0}};
            spi_rx_shift_reg_stage2 <= {DATA_WIDTH{1'b0}};
            spi_active_stage2       <= 1'b0;
            sclk_en_stage2          <= 1'b0;
        end else begin
            spi_fsm_state_stage2    <= spi_fsm_state_stage1;
            spi_bit_count_stage2    <= spi_bit_count_stage1;
            spi_tx_shift_reg_stage2 <= spi_tx_shift_reg_stage1;
            spi_rx_shift_reg_stage2 <= spi_rx_shift_reg_stage1;
            spi_active_stage2       <= spi_active_stage1;
            sclk_en_stage2          <= sclk_en_stage1;
        end
    end

    // ============================================
    // SPI Clock and MOSI Output (Synchronized)
    // ============================================

    reg [1:0] sclk_div_counter;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk <= 1'b0;
            sclk_div_counter <= 2'b00;
        end else if (sclk_en_stage2) begin
            sclk_div_counter <= sclk_div_counter + 1'b1;
            if (sclk_div_counter == 2'b01) begin
                sclk <= ~sclk;
            end
        end else begin
            sclk <= 1'b0;
            sclk_div_counter <= 2'b00;
        end
    end

    assign mosi = spi_tx_shift_reg_stage2[DATA_WIDTH-1];

endmodule