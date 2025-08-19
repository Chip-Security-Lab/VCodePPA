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
    reg [7:0] spi_cmd;
    reg [2:0] spi_bit_count;
    
    // Intermediate combination logic signals
    wire [15:0] crc_next1, crc_next2, crc_next3;
    wire crc_msb;
    wire poly_select;
    
    // Restructured pipeline registers
    reg [15:0] crc_reg;
    reg [7:0] data_reg1, data_reg2;
    reg data_valid_reg1, data_valid_reg2, data_valid_reg3;
    
    // SPI miso output now directly uses the MSB bit from the intermediate logic
    assign crc_msb = crc_reg[15];
    assign spi_miso = crc_msb;
    
    // Intermediate combination logic for CRC calculation
    assign crc_next1 = {crc_reg[14:0], 1'b0};
    assign poly_select = crc_reg[15] ^ data_reg1[0];
    assign crc_next2 = poly_select ? (crc_next1 ^ polynomial) : crc_next1;
    assign crc_next3 = data_valid_reg2 ? crc_next2 : crc_next1;
    
    always @(posedge clk) begin
        if (rst) begin
            polynomial <= DEFAULT_POLY;
            crc_reg <= 16'hFFFF;
            crc_out <= 16'hFFFF;
            data_reg1 <= 8'h00;
            data_reg2 <= 8'h00;
            data_valid_reg1 <= 1'b0;
            data_valid_reg2 <= 1'b0;
            data_valid_reg3 <= 1'b0;
        end else begin
            // SPI command processing moved earlier in the pipeline
            if (!spi_cs && spi_clk) begin
                spi_cmd <= {spi_cmd[6:0], spi_mosi};
                if (spi_cmd[7:0] == 8'hA5) polynomial <= {polynomial[14:0], spi_mosi};
            end
            
            // Input data registration
            data_reg1 <= data;
            data_valid_reg1 <= data_valid;
            
            // Move to next pipeline stage
            data_reg2 <= data_reg1;
            data_valid_reg2 <= data_valid_reg1;
            data_valid_reg3 <= data_valid_reg2;
            
            // CRC register update - moved before final computation
            crc_reg <= crc_next3;
            
            // Final CRC output - now just a transfer of the calculated value
            if (data_valid_reg3) begin
                crc_out <= crc_reg;
            end
        end
    end
endmodule