//SystemVerilog
module spi_configurable_crc(
    input wire clk,
    input wire rst,
    input wire spi_cs,
    input wire spi_clk,
    input wire spi_mosi,
    output wire spi_miso,
    input wire [7:0] data,
    input wire data_valid,
    output reg [15:0] crc_out
);
    parameter [15:0] DEFAULT_POLY = 16'h1021;
    reg [15:0] polynomial;
    reg [7:0] spi_cmd, spi_data;
    reg [2:0] spi_bit_count;
    assign spi_miso = crc_out[15];
    
    // Reset and polynomial configuration
    always @(posedge clk) begin
        if (rst) begin
            polynomial <= DEFAULT_POLY;
            crc_out <= 16'hFFFF;
        end
    end
    
    // SPI command shift register
    always @(posedge clk) begin
        if (!spi_cs && spi_clk) begin
            spi_cmd <= {spi_cmd[6:0], spi_mosi};
        end
    end
    
    // Polynomial update based on SPI command
    always @(posedge clk) begin
        if (!spi_cs && spi_clk && (spi_cmd[7:0] == 8'hA5)) begin
            polynomial <= {polynomial[14:0], spi_mosi};
        end
    end
    
    // CRC calculation
    always @(posedge clk) begin
        if (data_valid) begin
            crc_out <= {crc_out[14:0], 1'b0} ^ 
                     ((crc_out[15] ^ data[0]) ? polynomial : 16'h0000);
        end
    end
endmodule