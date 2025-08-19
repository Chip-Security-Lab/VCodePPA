//SystemVerilog
// Top-level SPI Master with Pipelined FIFO Controller
module spi_master_fifo #(
    parameter FIFO_DEPTH = 16,
    parameter DATA_WIDTH = 8
)(
    input clk,
    input rst_n,
    
    // FIFO interface
    input [DATA_WIDTH-1:0] tx_data,
    input tx_write,
    output tx_full,
    output [DATA_WIDTH-1:0] rx_data,
    output rx_valid,
    input rx_read,
    output rx_empty,
    
    // SPI interface
    output sclk,
    output cs_n,
    output mosi,
    input miso
);

    // Internal signals for FIFO control
    wire [DATA_WIDTH-1:0] tx_fifo_data_out;
    wire tx_fifo_empty;
    wire tx_fifo_rd_en_stage1;
    wire tx_fifo_rd_en_stage2;
    wire tx_fifo_wr_en;
    wire [DATA_WIDTH-1:0] rx_fifo_data_in_stage1;
    wire [DATA_WIDTH-1:0] rx_fifo_data_in_stage2;
    wire rx_fifo_wr_en_stage1;
    wire rx_fifo_wr_en_stage2;
    wire rx_fifo_full;
    wire [DATA_WIDTH-1:0] rx_fifo_data_out;
    wire rx_fifo_rd_en;

    // Internal signals for SPI core
    wire [DATA_WIDTH-1:0] spi_tx_data_stage1;
    wire [DATA_WIDTH-1:0] spi_tx_data_stage2;
    wire [DATA_WIDTH-1:0] spi_rx_data_stage1;
    wire [DATA_WIDTH-1:0] spi_rx_data_stage2;
    wire spi_tx_data_valid_stage1;
    wire spi_tx_data_valid_stage2;
    wire spi_rx_data_valid_stage1;
    wire spi_rx_data_valid_stage2;
    wire spi_tx_data_rd_stage1;
    wire spi_tx_data_rd_stage2;
    wire spi_cs_n;
    wire spi_sclk;
    wire spi_mosi;

    // Pipeline registers for TX FIFO read enable and data
    reg tx_fifo_rd_en_pipe_stage1;
    reg tx_fifo_rd_en_pipe_stage2;
    reg [DATA_WIDTH-1:0] tx_fifo_data_pipe_stage1;
    reg [DATA_WIDTH-1:0] tx_fifo_data_pipe_stage2;
    reg tx_fifo_empty_pipe_stage1;
    reg tx_fifo_empty_pipe_stage2;

    // Pipeline registers for RX FIFO write enable and data
    reg rx_fifo_wr_en_pipe_stage1;
    reg rx_fifo_wr_en_pipe_stage2;
    reg [DATA_WIDTH-1:0] rx_fifo_data_in_pipe_stage1;
    reg [DATA_WIDTH-1:0] rx_fifo_data_in_pipe_stage2;

    // Pipeline registers for SPI RX valid
    reg spi_rx_data_valid_pipe_stage1;
    reg spi_rx_data_valid_pipe_stage2;
    reg [DATA_WIDTH-1:0] spi_rx_data_pipe_stage1;
    reg [DATA_WIDTH-1:0] spi_rx_data_pipe_stage2;

    // TX FIFO: Stores data to be transmitted over SPI
    spi_fifo #(
        .FIFO_DEPTH(FIFO_DEPTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) tx_fifo_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_data(tx_data),
        .wr_en(tx_write),
        .rd_data(tx_fifo_data_out),
        .rd_en(tx_fifo_rd_en_pipe_stage2),
        .empty(tx_fifo_empty),
        .full(tx_full),
        .count(), // unused
        .rd_ptr(), // unused
        .wr_ptr()  // unused
    );

    // RX FIFO: Stores received data from SPI
    spi_fifo #(
        .FIFO_DEPTH(FIFO_DEPTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) rx_fifo_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_data(rx_fifo_data_in_pipe_stage2),
        .wr_en(rx_fifo_wr_en_pipe_stage2),
        .rd_data(rx_fifo_data_out),
        .rd_en(rx_read),
        .empty(rx_empty),
        .full(rx_fifo_full),
        .count(), // unused
        .rd_ptr(), // unused
        .wr_ptr()  // unused
    );

    assign rx_data = rx_fifo_data_out;
    assign rx_valid = ~rx_empty;

    // --- Pipeline stage 1: Register TX FIFO output for SPI Core ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_fifo_data_pipe_stage1 <= {DATA_WIDTH{1'b0}};
            tx_fifo_rd_en_pipe_stage1 <= 1'b0;
            tx_fifo_empty_pipe_stage1 <= 1'b1;
        end else begin
            tx_fifo_data_pipe_stage1 <= tx_fifo_data_out;
            tx_fifo_rd_en_pipe_stage1 <= ~tx_fifo_empty;
            tx_fifo_empty_pipe_stage1 <= tx_fifo_empty;
        end
    end

    // --- Pipeline stage 2: Register TX FIFO output again for SPI Core ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_fifo_data_pipe_stage2 <= {DATA_WIDTH{1'b0}};
            tx_fifo_rd_en_pipe_stage2 <= 1'b0;
            tx_fifo_empty_pipe_stage2 <= 1'b1;
        end else begin
            tx_fifo_data_pipe_stage2 <= tx_fifo_data_pipe_stage1;
            tx_fifo_rd_en_pipe_stage2 <= tx_fifo_rd_en_pipe_stage1;
            tx_fifo_empty_pipe_stage2 <= tx_fifo_empty_pipe_stage1;
        end
    end

    // --- Pipeline stage 1: RX FIFO write enable/data from SPI Core ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_fifo_data_in_pipe_stage1 <= {DATA_WIDTH{1'b0}};
            rx_fifo_wr_en_pipe_stage1 <= 1'b0;
        end else begin
            rx_fifo_data_in_pipe_stage1 <= spi_rx_data_pipe_stage2;
            rx_fifo_wr_en_pipe_stage1 <= spi_rx_data_valid_pipe_stage2;
        end
    end

    // --- Pipeline stage 2: RX FIFO write enable/data ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_fifo_data_in_pipe_stage2 <= {DATA_WIDTH{1'b0}};
            rx_fifo_wr_en_pipe_stage2 <= 1'b0;
        end else begin
            rx_fifo_data_in_pipe_stage2 <= rx_fifo_data_in_pipe_stage1;
            rx_fifo_wr_en_pipe_stage2 <= rx_fifo_wr_en_pipe_stage1;
        end
    end

    // --- SPI RX data pipeline stages ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_rx_data_pipe_stage1 <= {DATA_WIDTH{1'b0}};
            spi_rx_data_valid_pipe_stage1 <= 1'b0;
            spi_rx_data_pipe_stage2 <= {DATA_WIDTH{1'b0}};
            spi_rx_data_valid_pipe_stage2 <= 1'b0;
        end else begin
            spi_rx_data_pipe_stage1 <= spi_rx_data_stage2;
            spi_rx_data_valid_pipe_stage1 <= spi_rx_data_valid_stage2;
            spi_rx_data_pipe_stage2 <= spi_rx_data_pipe_stage1;
            spi_rx_data_valid_pipe_stage2 <= spi_rx_data_valid_pipe_stage1;
        end
    end

    // --- SPI Master Core: Handles SPI protocol and bit shifting with pipeline ---
    spi_master_core_pipeline #(
        .DATA_WIDTH(DATA_WIDTH)
    ) spi_core_inst (
        .clk(clk),
        .rst_n(rst_n),
        .tx_data(tx_fifo_data_pipe_stage2),
        .tx_data_valid(tx_fifo_rd_en_pipe_stage2),
        .tx_data_rd(), // not used at top level
        .rx_data(spi_rx_data_stage2),
        .rx_data_valid(spi_rx_data_valid_stage2),
        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
        .miso(miso)
    );

endmodule

//------------------------------------------------------------------------------
// FIFO Module: Parameterized synchronous FIFO for TX and RX (unchanged)
//------------------------------------------------------------------------------
module spi_fifo #(
    parameter FIFO_DEPTH = 16,
    parameter DATA_WIDTH = 8
)(
    input clk,
    input rst_n,
    input [DATA_WIDTH-1:0] wr_data,
    input wr_en,
    output [DATA_WIDTH-1:0] rd_data,
    input rd_en,
    output empty,
    output full,
    output reg [$clog2(FIFO_DEPTH):0] count,
    output reg [$clog2(FIFO_DEPTH)-1:0] rd_ptr,
    output reg [$clog2(FIFO_DEPTH)-1:0] wr_ptr
);
    // FIFO memory array
    reg [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];

    // Output data
    assign rd_data = fifo_mem[rd_ptr];
    assign empty = (count == 0);
    assign full = (count == FIFO_DEPTH);

    // FIFO pointers and count update logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count  <= 0;
            rd_ptr <= 0;
            wr_ptr <= 0;
        end else begin
            // Write operation
            if (wr_en && !full) begin
                fifo_mem[wr_ptr] <= wr_data;
                wr_ptr <= (wr_ptr + 1) % FIFO_DEPTH;
                count  <= count + 1;
            end
            // Read operation
            if (rd_en && !empty) begin
                rd_ptr <= (rd_ptr + 1) % FIFO_DEPTH;
                count  <= count - 1;
            end
        end
    end
endmodule

//------------------------------------------------------------------------------
// SPI Master Core Module: Pipelined version
//------------------------------------------------------------------------------
module spi_master_core_pipeline #(
    parameter DATA_WIDTH = 8
)(
    input clk,
    input rst_n,
    input [DATA_WIDTH-1:0] tx_data,
    input tx_data_valid,
    output reg tx_data_rd, // only used internally
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg rx_data_valid,
    output reg sclk,
    output reg cs_n,
    output mosi,
    input miso
);
    // SPI transfer state machine
    localparam IDLE  = 2'b00, LOAD = 2'b01, TRANSFER = 2'b10, DONE = 2'b11;

    // Stage 1: FSM and control signals
    reg [1:0] state_stage1, next_state_stage1;
    reg [DATA_WIDTH-1:0] tx_data_stage1;
    reg tx_data_valid_stage1;

    // Stage 2: Shift registers and bit counters
    reg [1:0] state_stage2;
    reg [DATA_WIDTH-1:0] tx_shift_reg_stage2;
    reg [DATA_WIDTH-1:0] rx_shift_reg_stage2;
    reg [$clog2(DATA_WIDTH):0] bit_cnt_stage2;
    reg sclk_int_stage2;
    reg cs_n_int_stage2;
    reg tx_data_rd_stage2;
    reg rx_data_valid_stage2;
    reg [DATA_WIDTH-1:0] rx_data_stage2;

    // Stage 3: Output registers
    reg [DATA_WIDTH-1:0] rx_data_stage3;
    reg rx_data_valid_stage3;
    reg sclk_int_stage3;
    reg cs_n_int_stage3;

    // Valid pipeline
    reg valid_stage1, valid_stage2, valid_stage3;

    // Flush pipeline logic
    wire flush = ~rst_n;

    // Stage 1: FSM and input register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
            tx_data_stage1 <= {DATA_WIDTH{1'b0}};
            tx_data_valid_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            tx_data_stage1 <= tx_data;
            tx_data_valid_stage1 <= tx_data_valid;
            valid_stage1 <= 1'b1;
            case (state_stage1)
                IDLE: if (tx_data_valid) state_stage1 <= LOAD;
                LOAD: state_stage1 <= TRANSFER;
                TRANSFER: if (bit_cnt_stage2 == 0 && valid_stage2) state_stage1 <= DONE;
                DONE: state_stage1 <= IDLE;
                default: state_stage1 <= IDLE;
            endcase
        end
    end

    // Stage 2: Shift and count registers, FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= IDLE;
            tx_shift_reg_stage2 <= {DATA_WIDTH{1'b0}};
            rx_shift_reg_stage2 <= {DATA_WIDTH{1'b0}};
            bit_cnt_stage2 <= 0;
            sclk_int_stage2 <= 1'b0;
            cs_n_int_stage2 <= 1'b1;
            tx_data_rd_stage2 <= 1'b0;
            rx_data_valid_stage2 <= 1'b0;
            rx_data_stage2 <= {DATA_WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            tx_data_rd_stage2 <= 1'b0;
            rx_data_valid_stage2 <= 1'b0;
            case (state_stage1)
                IDLE: begin
                    sclk_int_stage2 <= 1'b0;
                    cs_n_int_stage2 <= 1'b1;
                end
                LOAD: begin
                    tx_shift_reg_stage2 <= tx_data_stage1;
                    rx_shift_reg_stage2 <= {DATA_WIDTH{1'b0}};
                    bit_cnt_stage2 <= DATA_WIDTH;
                    cs_n_int_stage2 <= 1'b0;
                    sclk_int_stage2 <= 1'b0;
                    tx_data_rd_stage2 <= 1'b1;
                end
                TRANSFER: begin
                    cs_n_int_stage2 <= 1'b0;
                    if (sclk_int_stage2 == 1'b0) begin // On falling edge, sample MISO
                        rx_shift_reg_stage2 <= {rx_shift_reg_stage2[DATA_WIDTH-2:0], miso};
                        sclk_int_stage2 <= 1'b1;
                    end else begin // On rising edge, shift MOSI
                        tx_shift_reg_stage2 <= {tx_shift_reg_stage2[DATA_WIDTH-2:0], 1'b0};
                        bit_cnt_stage2 <= bit_cnt_stage2 - 1;
                        sclk_int_stage2 <= 1'b0;
                    end
                end
                DONE: begin
                    cs_n_int_stage2 <= 1'b1;
                    rx_data_stage2 <= rx_shift_reg_stage2;
                    rx_data_valid_stage2 <= 1'b1;
                end
            endcase
            state_stage2 <= state_stage1; // Pipeline FSM
        end
    end

    // Stage 3: Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data_stage3 <= {DATA_WIDTH{1'b0}};
            rx_data_valid_stage3 <= 1'b0;
            sclk_int_stage3 <= 1'b0;
            cs_n_int_stage3 <= 1'b1;
            valid_stage3 <= 1'b0;
        end else begin
            rx_data_stage3 <= rx_data_stage2;
            rx_data_valid_stage3 <= rx_data_valid_stage2;
            sclk_int_stage3 <= sclk_int_stage2;
            cs_n_int_stage3 <= cs_n_int_stage2;
            valid_stage3 <= valid_stage2;
        end
    end

    assign mosi = tx_shift_reg_stage2[DATA_WIDTH-1];
    assign sclk = sclk_int_stage3;
    assign cs_n = cs_n_int_stage3;
    assign rx_data = rx_data_stage3;
    assign rx_data_valid = rx_data_valid_stage3;
    assign tx_data_rd = tx_data_rd_stage2;

endmodule