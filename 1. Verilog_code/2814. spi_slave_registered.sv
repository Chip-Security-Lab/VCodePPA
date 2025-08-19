module spi_slave_registered (
    input clk_i, rst_i,
    input sclk_i, cs_n_i, mosi_i,
    output miso_o,
    output reg [7:0] rx_data,
    input [7:0] tx_data,
    output reg rx_valid
);
    reg [7:0] rx_shift_reg, tx_shift_reg;
    reg [2:0] bit_count;
    reg sclk_r, sclk_r2;
    wire sclk_rising, sclk_falling;
    
    // Edge detection
    always @(posedge clk_i) begin
        sclk_r <= sclk_i;
        sclk_r2 <= sclk_r;
    end
    
    assign sclk_rising = sclk_r & ~sclk_r2;
    assign sclk_falling = ~sclk_r & sclk_r2;
    assign miso_o = tx_shift_reg[7];
    
    always @(posedge clk_i) begin
        if (rst_i) begin
            rx_shift_reg <= 8'h0; tx_shift_reg <= 8'h0;
            bit_count <= 3'h0; rx_valid <= 1'b0;
        end else if (!cs_n_i) begin
            if (sclk_rising) begin
                rx_shift_reg <= {rx_shift_reg[6:0], mosi_i};
                bit_count <= bit_count + 3'h1;
                rx_valid <= (bit_count == 3'h7) ? 1'b1 : 1'b0;
                if (bit_count == 3'h7) rx_data <= {rx_shift_reg[6:0], mosi_i};
            end
            if (sclk_falling && bit_count == 3'h0) tx_shift_reg <= tx_data;
            else if (sclk_falling) tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
        end else rx_valid <= 1'b0;
    end
endmodule