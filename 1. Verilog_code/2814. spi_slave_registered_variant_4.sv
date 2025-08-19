//SystemVerilog

//---------------------------
// SPI Shift Register Module
//---------------------------
// Handles RX and TX shift register operations and bit counting.
module spi_shift_register #(
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  cs_n,
    input  wire                  sclk_rising,
    input  wire                  sclk_falling,
    input  wire                  mosi,
    input  wire [DATA_WIDTH-1:0] tx_data,
    output reg  [DATA_WIDTH-1:0] rx_shift,
    output reg  [DATA_WIDTH-1:0] tx_shift,
    output reg  [2:0]            bit_count,
    output reg  [DATA_WIDTH-1:0] rx_data,
    output reg                   rx_valid
);
    // Purpose: Handle SPI shift in/out and bit counting
    always @(posedge clk) begin
        if (rst) begin
            rx_shift   <= {DATA_WIDTH{1'b0}};
            tx_shift   <= {DATA_WIDTH{1'b0}};
            bit_count  <= 3'h0;
            rx_valid   <= 1'b0;
            rx_data    <= {DATA_WIDTH{1'b0}};
        end else if (!cs_n) begin
            if (sclk_rising) begin
                rx_shift  <= {rx_shift[DATA_WIDTH-2:0], mosi};
                bit_count <= bit_count + 3'h1;
                rx_valid  <= (bit_count == 3'h7) ? 1'b1 : 1'b0;
                if (bit_count == 3'h7)
                    rx_data <= {rx_shift[DATA_WIDTH-2:0], mosi};
            end
            if (sclk_falling && bit_count == 3'h0) begin
                tx_shift <= tx_data;
            end else if (sclk_falling) begin
                tx_shift <= {tx_shift[DATA_WIDTH-2:0], 1'b0};
            end
        end else begin
            rx_valid <= 1'b0;
        end
    end
endmodule

//---------------------------
// SPI Clock Edge Detector
//---------------------------
// Synchronizes and detects rising/falling edges of SCLK.
module spi_sclk_edge_detector (
    input  wire clk,
    input  wire rst,
    input  wire sclk,
    output wire sclk_rising,
    output wire sclk_falling
);
    reg sclk_sync1, sclk_sync2;
    reg sclk_buf1, sclk_buf2;

    // Purpose: Synchronize SCLK to clk domain
    always @(posedge clk) begin
        sclk_sync1 <= sclk;
        sclk_sync2 <= sclk_sync1;
    end

    // Purpose: Buffer SCLK to reduce fanout
    always @(posedge clk) begin
        sclk_buf1 <= sclk_sync1;
        sclk_buf2 <= sclk_sync1;
    end

    // Purpose: Detect edges
    assign sclk_rising  =  sclk_buf1 & ~sclk_sync2;
    assign sclk_falling = ~sclk_buf2 &  sclk_sync2;
endmodule

//---------------------------
// SPI Bit Count Buffer
//---------------------------
// Provides buffered copies of bit_count to reduce fanout.
// Only used for fanout optimization.
module spi_bit_count_buffer (
    input  wire [2:0] bit_count_in,
    input  wire       clk,
    output reg  [2:0] bit_count_buf1,
    output reg  [2:0] bit_count_buf2
);
    // Purpose: Buffer bit_count for fanout
    always @(posedge clk) begin
        bit_count_buf1 <= bit_count_in;
        bit_count_buf2 <= bit_count_in;
    end
endmodule

//---------------------------
// Top-Level SPI Slave Registered Module
//---------------------------
module spi_slave_registered (
    input  wire        clk_i,
    input  wire        rst_i,
    input  wire        sclk_i,
    input  wire        cs_n_i,
    input  wire        mosi_i,
    output wire        miso_o,
    output wire [7:0]  rx_data,
    input  wire [7:0]  tx_data,
    output wire        rx_valid
);

    // Internal wires for inter-module connections
    wire [7:0] rx_shift_reg_w;
    wire [7:0] tx_shift_reg_w;
    wire [2:0] bit_count_reg_w;
    wire [7:0] rx_data_w;
    wire       rx_valid_w;
    wire       sclk_rising_w;
    wire       sclk_falling_w;
    wire [2:0] bit_count_buf1_w, bit_count_buf2_w;

    // SCLK edge detector submodule
    spi_sclk_edge_detector u_sclk_edge_detector (
        .clk           (clk_i),
        .rst           (rst_i),
        .sclk          (sclk_i),
        .sclk_rising   (sclk_rising_w),
        .sclk_falling  (sclk_falling_w)
    );

    // SPI shift register & bit counter submodule
    spi_shift_register #(
        .DATA_WIDTH(8)
    ) u_spi_shift_register (
        .clk         (clk_i),
        .rst         (rst_i),
        .cs_n        (cs_n_i),
        .sclk_rising (sclk_rising_w),
        .sclk_falling(sclk_falling_w),
        .mosi        (mosi_i),
        .tx_data     (tx_data),
        .rx_shift    (rx_shift_reg_w),
        .tx_shift    (tx_shift_reg_w),
        .bit_count   (bit_count_reg_w),
        .rx_data     (rx_data_w),
        .rx_valid    (rx_valid_w)
    );

    // Bit count buffer submodule (for fanout)
    spi_bit_count_buffer u_bit_count_buffer (
        .bit_count_in   (bit_count_reg_w),
        .clk            (clk_i),
        .bit_count_buf1 (bit_count_buf1_w),
        .bit_count_buf2 (bit_count_buf2_w)
    );

    // Output assignments
    assign miso_o   = tx_shift_reg_w[7];
    assign rx_data  = rx_data_w;
    assign rx_valid = rx_valid_w;

endmodule