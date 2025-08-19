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
    reg [2:0] state;
    
    localparam STATE_IDLE = 3'd0,
               STATE_SPI_CMD = 3'd1,
               STATE_DATA_VALID = 3'd2;
    
    assign spi_miso = crc_out[15];
    
    // 状态选择逻辑
    always @(*) begin
        state = STATE_IDLE;
        if (rst) 
            state = STATE_IDLE;
        else if (!spi_cs && spi_clk)
            state = STATE_SPI_CMD;
        else if (data_valid)
            state = STATE_DATA_VALID;
    end
    
    // 主逻辑处理
    always @(posedge clk) begin
        case (state)
            STATE_IDLE: begin
                polynomial <= DEFAULT_POLY;
                crc_out <= 16'hFFFF;
            end
            
            STATE_SPI_CMD: begin
                spi_cmd <= {spi_cmd[6:0], spi_mosi};
                if (spi_cmd[7:0] == 8'hA5)
                    polynomial <= {polynomial[14:0], spi_mosi};
            end
            
            STATE_DATA_VALID: begin
                crc_out <= {crc_out[14:0], 1'b0} ^ 
                         ((crc_out[15] ^ data[0]) ? polynomial : 16'h0000);
            end
            
            default: begin
                // 保持当前状态
            end
        endcase
    end
endmodule