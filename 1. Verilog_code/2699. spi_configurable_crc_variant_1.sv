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
    output wire [15:0] crc_out
);
    parameter [15:0] DEFAULT_POLY = 16'h1021;
    
    // Stage 1: SPI and configuration registers
    reg [15:0] polynomial_stage1;
    reg [7:0] spi_cmd_stage1;
    reg [15:0] crc_stage1;
    reg valid_stage1;
    reg [7:0] data_stage1;
    
    // Stage 2: CRC calculation stage 1 (process first 4 bits)
    reg [15:0] polynomial_stage2;
    reg [15:0] crc_stage2;
    reg valid_stage2;
    reg [3:0] data_stage2;
    
    // Stage 3: CRC calculation stage 2 (process remaining 4 bits)
    reg [15:0] polynomial_stage3;
    reg [15:0] crc_stage3;
    
    // Output assignment
    assign spi_miso = crc_stage1[15];
    assign crc_out = crc_stage3;
    
    // Stage 1: SPI handling and input registration
    always @(posedge clk) begin
        if (rst) begin
            polynomial_stage1 <= DEFAULT_POLY;
            spi_cmd_stage1 <= 8'h0;
            crc_stage1 <= 16'hFFFF;
            valid_stage1 <= 1'b0;
            data_stage1 <= 8'h0;
        end else begin
            valid_stage1 <= data_valid;
            if (data_valid) begin
                data_stage1 <= data;
            end
            
            if (!spi_cs && spi_clk) begin
                spi_cmd_stage1 <= {spi_cmd_stage1[6:0], spi_mosi};
                if (spi_cmd_stage1[7:0] == 8'hA5) begin
                    polynomial_stage1 <= {polynomial_stage1[14:0], spi_mosi};
                end
            end
        end
    end
    
    // Function to calculate CRC for a single bit
    function [15:0] calc_crc_bit;
        input [15:0] crc_in;
        input bit_in;
        input [15:0] poly;
        begin
            calc_crc_bit = {crc_in[14:0], 1'b0} ^ ((crc_in[15] ^ bit_in) ? poly : 16'h0000);
        end
    endfunction
    
    // Stage 2: CRC calculation for first 4 bits
    always @(posedge clk) begin
        if (rst) begin
            polynomial_stage2 <= DEFAULT_POLY;
            crc_stage2 <= 16'hFFFF;
            valid_stage2 <= 1'b0;
            data_stage2 <= 4'h0;
        end else begin
            valid_stage2 <= valid_stage1;
            polynomial_stage2 <= polynomial_stage1;
            data_stage2 <= data_stage1[7:4];
            
            if (valid_stage1) begin
                // Pipeline first 4 bits of CRC calculation
                reg [15:0] temp_crc;
                temp_crc = crc_stage1;
                
                temp_crc = calc_crc_bit(temp_crc, data_stage1[0], polynomial_stage1);
                temp_crc = calc_crc_bit(temp_crc, data_stage1[1], polynomial_stage1);
                temp_crc = calc_crc_bit(temp_crc, data_stage1[2], polynomial_stage1);
                temp_crc = calc_crc_bit(temp_crc, data_stage1[3], polynomial_stage1);
                
                crc_stage2 <= temp_crc;
            end else begin
                crc_stage2 <= crc_stage1;
            end
        end
    end
    
    // Stage 3: CRC calculation for remaining 4 bits
    always @(posedge clk) begin
        if (rst) begin
            polynomial_stage3 <= DEFAULT_POLY;
            crc_stage3 <= 16'hFFFF;
        end else begin
            polynomial_stage3 <= polynomial_stage2;
            
            if (valid_stage2) begin
                // Pipeline remaining 4 bits of CRC calculation
                reg [15:0] temp_crc;
                temp_crc = crc_stage2;
                
                temp_crc = calc_crc_bit(temp_crc, data_stage2[0], polynomial_stage2);
                temp_crc = calc_crc_bit(temp_crc, data_stage2[1], polynomial_stage2);
                temp_crc = calc_crc_bit(temp_crc, data_stage2[2], polynomial_stage2);
                temp_crc = calc_crc_bit(temp_crc, data_stage2[3], polynomial_stage2);
                
                crc_stage3 <= temp_crc;
            end else begin
                crc_stage3 <= crc_stage2;
            end
        end
    end
    
endmodule