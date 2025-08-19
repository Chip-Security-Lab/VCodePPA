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

    reg [$clog2(WIDTH):0]    spi_clk_count;
    reg [WIDTH-1:0]          shift_reg;
    reg                      spi_clk_sync_0, spi_clk_sync_1;
    wire                     spi_clk_rising;

    // Double-flop synchronizer for SPI clock to avoid metastability
    always @(posedge i_Clk) begin
        spi_clk_sync_0 <= i_SPI_Clk;
        spi_clk_sync_1 <= spi_clk_sync_0;
    end

    assign spi_clk_rising = (spi_clk_sync_0 & ~spi_clk_sync_1);

    // MISO output is MSB of shift register
    assign o_SPI_MISO = shift_reg[WIDTH-1];

    // Conditional Invert Subtractor for 8-bit
    function [WIDTH-1:0] conditional_invert_subtractor;
        input [WIDTH-1:0] minuend;
        input [WIDTH-1:0] subtrahend;
        reg   [WIDTH-1:0] subtrahend_inv;
        reg               carry_in;
        begin
            subtrahend_inv = ~subtrahend;
            carry_in = 1'b1;
            conditional_invert_subtractor = minuend + subtrahend_inv + carry_in;
        end
    endfunction

    always @(posedge i_Clk) begin
        if (i_SPI_CS_n) begin
            spi_clk_count <= 0;
            shift_reg     <= i_TX_Byte;
            o_RX_Byte     <= {WIDTH{1'b0}};
            o_RX_Done     <= 1'b0;
        end else begin
            o_RX_Done <= 1'b0;
            if (spi_clk_rising) begin
                shift_reg <= {shift_reg[WIDTH-2:0], i_SPI_MOSI};
                if (spi_clk_count == (WIDTH-1)) begin
                    // Use conditional invert subtractor to compute received byte minus 0 (functionally same as received byte)
                    o_RX_Byte <= conditional_invert_subtractor({shift_reg[WIDTH-2:0], i_SPI_MOSI}, {WIDTH{1'b0}});
                    o_RX_Done <= 1'b1;
                    spi_clk_count <= 0;
                end else begin
                    // Use conditional invert subtractor to increment count
                    spi_clk_count <= conditional_invert_subtractor(spi_clk_count, {{($clog2(WIDTH)){1'b0}}, 1'b1});
                end
            end
        end
    end

endmodule