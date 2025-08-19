module spi_codec #(parameter DATA_WIDTH=8) (
    input clk, rst_n, en,
    input mosi, cs_n,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg data_valid
);
    reg [2:0] bit_cnt;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            bit_cnt <= 0;
            rx_data <= 0;
            data_valid <= 0;
        end else if(en && !cs_n) begin
            rx_data <= {rx_data[DATA_WIDTH-2:0], mosi};
            bit_cnt <= (bit_cnt == DATA_WIDTH-1) ? 0 : bit_cnt + 1;
            data_valid <= (bit_cnt == DATA_WIDTH-1);
        end
    end
endmodule