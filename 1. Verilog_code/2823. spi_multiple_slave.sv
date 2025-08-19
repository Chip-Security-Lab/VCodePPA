module spi_multiple_slave #(
    parameter SLAVE_COUNT = 4,
    parameter DATA_WIDTH = 8
)(
    input clk, rst_n,
    input [DATA_WIDTH-1:0] tx_data,
    input [$clog2(SLAVE_COUNT)-1:0] slave_select,
    input start_transfer,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg transfer_done,
    
    output spi_clk,
    output reg [SLAVE_COUNT-1:0] spi_cs_n,
    output spi_mosi,
    input [SLAVE_COUNT-1:0] spi_miso
);
    reg [DATA_WIDTH-1:0] shift_reg;
    reg [$clog2(DATA_WIDTH):0] bit_count;
    reg busy, spi_clk_en;
    wire active_miso;
    
    assign spi_clk = busy ? clk : 1'b0;
    assign spi_mosi = shift_reg[DATA_WIDTH-1];
    assign active_miso = spi_miso[slave_select];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 0;
            bit_count <= 0;
            busy <= 1'b0;
            transfer_done <= 1'b0;
            spi_cs_n <= {SLAVE_COUNT{1'b1}};
        end else if (start_transfer && !busy) begin
            shift_reg <= tx_data;
            bit_count <= DATA_WIDTH;
            busy <= 1'b1;
            transfer_done <= 1'b0;
            spi_cs_n <= ~(1'b1 << slave_select);
        end else if (busy && bit_count > 0) begin
            if (!spi_clk) begin // rising edge of SPI clock
                shift_reg <= {shift_reg[DATA_WIDTH-2:0], active_miso};
                bit_count <= bit_count - 1;
            end
            
            if (bit_count == 1 && spi_clk) begin
                busy <= 1'b0;
                transfer_done <= 1'b1;
                rx_data <= {shift_reg[DATA_WIDTH-2:0], active_miso};
                spi_cs_n <= {SLAVE_COUNT{1'b1}};
            end
        end else transfer_done <= 1'b0;
    end
endmodule