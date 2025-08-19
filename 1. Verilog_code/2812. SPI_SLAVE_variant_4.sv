//SystemVerilog
module SPI_SLAVE #(parameter WIDTH = 8) (
    input  wire              i_Clk,
    input  wire              i_SPI_CS_n,
    input  wire              i_SPI_Clk,
    input  wire              i_SPI_MOSI,
    output wire              o_SPI_MISO,
    input  wire [WIDTH-1:0]  i_TX_Byte,
    output reg  [WIDTH-1:0]  o_RX_Byte,
    output reg               o_RX_Done
);

// Stage 1: Synchronize SPI_Clk to i_Clk domain and edge detection
reg spi_clk_sync_stage1;
reg spi_clk_sync_stage2;
reg spi_clk_rising_edge_stage1;
reg spi_clk_rising_edge_stage2;

always @(posedge i_Clk) begin
    if (i_SPI_CS_n) begin
        spi_clk_sync_stage1 <= 1'b0;
        spi_clk_sync_stage2 <= 1'b0;
    end else begin
        spi_clk_sync_stage1 <= i_SPI_Clk;
        spi_clk_sync_stage2 <= spi_clk_sync_stage1;
    end
end

always @(posedge i_Clk) begin
    if (i_SPI_CS_n) begin
        spi_clk_rising_edge_stage1 <= 1'b0;
        spi_clk_rising_edge_stage2 <= 1'b0;
    end else begin
        spi_clk_rising_edge_stage1 <= spi_clk_sync_stage2 & ~spi_clk_sync_stage1;
        spi_clk_rising_edge_stage2 <= spi_clk_rising_edge_stage1;
    end
end

wire spi_clk_rising_edge = spi_clk_rising_edge_stage2;

// Stage 2: Shift register input capture and counting
reg [WIDTH-1:0] shift_reg_stage1;
reg [WIDTH-1:0] shift_reg_stage2;
reg [2:0]       spi_clk_count_stage1;
reg [2:0]       spi_clk_count_stage2;

// 3-bit Two's Complement Subtractor
function [2:0] twos_complement_sub;
    input [2:0] minuend;
    input [2:0] subtrahend;
    reg [2:0] subtrahend_inv;
    begin
        subtrahend_inv = ~subtrahend; // 1's complement
        twos_complement_sub = minuend + subtrahend_inv + 3'b001; // +1 for 2's complement
    end
endfunction

always @(posedge i_Clk) begin
    if (i_SPI_CS_n) begin
        shift_reg_stage1      <= i_TX_Byte;
        spi_clk_count_stage1  <= 3'd0;
    end else if (spi_clk_rising_edge) begin
        shift_reg_stage1      <= {shift_reg_stage1[WIDTH-2:0], i_SPI_MOSI};
        spi_clk_count_stage1  <= spi_clk_count_stage1 + 1'b1;
    end
end

always @(posedge i_Clk) begin
    if (i_SPI_CS_n) begin
        shift_reg_stage2     <= i_TX_Byte;
        spi_clk_count_stage2 <= 3'd0;
    end else begin
        shift_reg_stage2     <= shift_reg_stage1;
        spi_clk_count_stage2 <= spi_clk_count_stage1;
    end
end

// Stage 3: Output byte latch and done signal
reg [WIDTH-1:0] rx_byte_stage1;
reg [WIDTH-1:0] rx_byte_stage2;
reg             rx_done_stage1;
reg             rx_done_stage2;

wire [2:0] width_minus_one;
assign width_minus_one = twos_complement_sub({3'b000} + WIDTH[2:0], 3'b001);

always @(posedge i_Clk) begin
    if (i_SPI_CS_n) begin
        rx_byte_stage1 <= {WIDTH{1'b0}};
        rx_done_stage1 <= 1'b0;
    end else if (spi_clk_rising_edge && (spi_clk_count_stage2 == width_minus_one)) begin
        rx_byte_stage1 <= {shift_reg_stage2[WIDTH-2:0], i_SPI_MOSI};
        rx_done_stage1 <= 1'b1;
    end else begin
        rx_done_stage1 <= 1'b0;
    end
end

always @(posedge i_Clk) begin
    if (i_SPI_CS_n) begin
        rx_byte_stage2 <= {WIDTH{1'b0}};
        rx_done_stage2 <= 1'b0;
    end else begin
        rx_byte_stage2 <= rx_byte_stage1;
        rx_done_stage2 <= rx_done_stage1;
    end
end

// Assign output signals
assign o_SPI_MISO = shift_reg_stage2[WIDTH-1];

always @(posedge i_Clk) begin
    if (i_SPI_CS_n) begin
        o_RX_Byte <= {WIDTH{1'b0}};
        o_RX_Done <= 1'b0;
    end else begin
        o_RX_Byte <= rx_byte_stage2;
        o_RX_Done <= rx_done_stage2;
    end
end

endmodule