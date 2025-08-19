module spi_master_configurable (
    input clock, reset,
    input cpol, cpha,
    input enable, load,
    input [7:0] tx_data,
    output [7:0] rx_data,
    output spi_clk, spi_mosi,
    input spi_miso,
    output cs_n, tx_ready
);
    reg [7:0] tx_shift, rx_shift;
    reg [3:0] count;
    reg sclk_i, ready;
    
    // Create SPI clock based on CPOL
    assign spi_clk = (cpol) ? ~sclk_i : sclk_i;
    assign spi_mosi = tx_shift[7];
    assign rx_data = rx_shift;
    assign tx_ready = ready;
    assign cs_n = ~enable;
    
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            count <= 4'd0; ready <= 1'b1; sclk_i <= 1'b0;
            tx_shift <= 8'h00; rx_shift <= 8'h00;
        end else if (load && ready) begin
            tx_shift <= tx_data; ready <= 1'b0; count <= 4'd8;
        end else if (!ready) begin
            sclk_i <= ~sclk_i;
            if ((sclk_i && !cpha) || (!sclk_i && cpha)) begin
                rx_shift <= {rx_shift[6:0], spi_miso};
            end
            if ((~sclk_i && !cpha) || (sclk_i && cpha)) begin
                tx_shift <= {tx_shift[6:0], 1'b0};
                count <= count - 4'd1;
                if (count == 4'd1) ready <= 1'b1;
            end
        end
    end
endmodule