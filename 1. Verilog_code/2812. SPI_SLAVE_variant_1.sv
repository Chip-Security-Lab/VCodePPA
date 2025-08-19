//SystemVerilog
module SPI_SLAVE #(parameter WIDTH = 8) (
    input wire i_Clk,
    input wire i_SPI_CS_n,
    input wire i_SPI_Clk,
    input wire i_SPI_MOSI,
    output wire o_SPI_MISO,
    input wire [WIDTH-1:0] i_TX_Byte,
    output reg [WIDTH-1:0] o_RX_Byte,
    output reg o_RX_Done
);
    reg [2:0] spi_clk_count;
    reg [WIDTH-1:0] shift_reg;

    assign o_SPI_MISO = shift_reg[WIDTH-1];

    always @(posedge i_Clk) begin
        spi_clk_count <= i_SPI_CS_n ? 3'b000 :
                        ({i_SPI_Clk, spi_clk_count[0]} == 2'b10) ?
                            ((spi_clk_count[2:1] == (WIDTH-1)) ?
                                {2'b00, 1'b1} : {spi_clk_count[2:1] + 1'b1, 1'b1}) :
                        ({i_SPI_Clk, spi_clk_count[0]} == 2'b00) ?
                            {spi_clk_count[2:1], 1'b0} :
                        spi_clk_count;

        shift_reg <= i_SPI_CS_n ? {WIDTH{1'b0}} :
                     (({i_SPI_Clk, spi_clk_count[0]} == 2'b10) ?
                        {shift_reg[WIDTH-2:0], i_SPI_MOSI} :
                        shift_reg);

        o_RX_Byte <= (i_SPI_CS_n ? {WIDTH{1'b0}} :
                     (({i_SPI_Clk, spi_clk_count[0]} == 2'b10) && (spi_clk_count[2:1] == (WIDTH-1))) ?
                        {shift_reg[WIDTH-2:0], i_SPI_MOSI} :
                        o_RX_Byte);

        o_RX_Done <= i_SPI_CS_n ? 1'b0 :
                     (({i_SPI_Clk, spi_clk_count[0]} == 2'b10) && (spi_clk_count[2:1] == (WIDTH-1))) ?
                        1'b1 : 1'b0;
    end
endmodule