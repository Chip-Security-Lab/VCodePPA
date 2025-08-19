module spi_master_basic #(parameter DATA_WIDTH = 8) (
    input clk, rst_n,
    input start_tx,
    input [DATA_WIDTH-1:0] tx_data,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg busy,
    output reg sclk, cs_n, mosi,
    input miso
);
    reg [DATA_WIDTH-1:0] shift_reg;
    reg [$clog2(DATA_WIDTH):0] bit_counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 0; busy <= 0; cs_n <= 1;
            sclk <= 0; shift_reg <= 0; rx_data <= 0;
        end else if (start_tx && !busy) begin
            busy <= 1; cs_n <= 0; bit_counter <= DATA_WIDTH;
            shift_reg <= tx_data;
        end else if (busy && bit_counter > 0) begin
            sclk <= ~sclk;
            if (sclk) begin
                shift_reg <= {shift_reg[DATA_WIDTH-2:0], miso};
                bit_counter <= bit_counter - 1;
            end else mosi <= shift_reg[DATA_WIDTH-1];
        end else if (busy && bit_counter == 0) begin
            busy <= 0; cs_n <= 1; rx_data <= shift_reg;
        end
    end
endmodule