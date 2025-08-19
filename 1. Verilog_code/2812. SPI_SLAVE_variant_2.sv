//SystemVerilog
module SPI_SLAVE #(parameter WIDTH = 8) (
    input wire i_Clk,
    input wire i_SPI_CS_n,
    input wire i_SPI_Clk,
    input wire i_SPI_MOSI,
    output wire o_SPI_MISO,
    input wire [WIDTH-1:0] i_TX_Byte,
    output wire [WIDTH-1:0] o_RX_Byte,
    output wire o_RX_Done
);
    reg [2:0] spi_clk_count_reg;
    reg [2:0] spi_clk_count_next;
    reg [WIDTH-1:0] shift_reg;
    reg [WIDTH-1:0] shift_reg_next;
    reg [WIDTH-1:0] rx_byte_reg;
    reg [WIDTH-1:0] rx_byte_next;
    reg rx_done_reg;
    reg rx_done_next;
    reg spi_clk_sync1, spi_clk_sync2;
    wire spi_clk_rising_edge;

    // Synchronize SPI clock to i_Clk domain
    always @(posedge i_Clk) begin
        spi_clk_sync1 <= i_SPI_Clk;
        spi_clk_sync2 <= spi_clk_sync1;
    end

    assign spi_clk_rising_edge = (spi_clk_sync1 & ~spi_clk_sync2);

    // Combinational logic for next state
    always @* begin
        shift_reg_next = shift_reg;
        spi_clk_count_next = spi_clk_count_reg;
        rx_byte_next = rx_byte_reg;
        rx_done_next = 1'b0;

        if (i_SPI_CS_n) begin
            shift_reg_next = i_TX_Byte;
            spi_clk_count_next = 3'b000;
            rx_done_next = 1'b0;
            rx_byte_next = rx_byte_reg;
        end else begin
            if (spi_clk_rising_edge) begin
                shift_reg_next = {shift_reg[WIDTH-2:0], i_SPI_MOSI};
                spi_clk_count_next[0] = 1'b1;
                if (spi_clk_count_reg[2:1] == WIDTH-1) begin
                    rx_byte_next = {shift_reg[WIDTH-2:0], i_SPI_MOSI};
                    rx_done_next = 1'b1;
                    spi_clk_count_next[2:1] = 2'b00;
                end else begin
                    spi_clk_count_next[2:1] = spi_clk_count_reg[2:1] + 1'b1;
                end
            end else if (!spi_clk_sync1) begin
                spi_clk_count_next[0] = 1'b0;
            end
        end
    end

    // Sequential logic with all registers moved before outputs
    always @(posedge i_Clk) begin
        shift_reg <= shift_reg_next;
        spi_clk_count_reg <= spi_clk_count_next;
        rx_byte_reg <= rx_byte_next;
        rx_done_reg <= rx_done_next;
    end

    assign o_SPI_MISO = shift_reg[WIDTH-1];
    assign o_RX_Byte = rx_byte_reg;
    assign o_RX_Done = rx_done_reg;
endmodule