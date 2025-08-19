module spi_receive_only(
    input spi_clk,
    input spi_cs_n,
    input spi_mosi,
    
    input sys_clk,
    input sys_rst_n,
    output reg [7:0] rx_data,
    output reg rx_valid
);
    reg [7:0] rx_shift;
    reg [2:0] bit_count;
    reg spi_cs_n_prev, transfer_active;
    reg [1:0] spi_clk_sync;
    
    wire spi_clk_rising = spi_clk_sync[0] & ~spi_clk_sync[1];
    
    // Synchronize SPI clock to system clock domain
    always @(posedge sys_clk) begin
        spi_clk_sync <= {spi_clk_sync[0], spi_clk};
    end
    
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            rx_shift <= 8'h00;
            bit_count <= 3'h0;
            rx_data <= 8'h00;
            rx_valid <= 1'b0;
            spi_cs_n_prev <= 1'b1;
            transfer_active <= 1'b0;
        end else begin
            spi_cs_n_prev <= spi_cs_n;
            rx_valid <= 1'b0;
            
            // Detect CS falling edge (start of transfer)
            if (spi_cs_n_prev && !spi_cs_n) begin
                transfer_active <= 1'b1;
                bit_count <= 3'h7;
            end
            
            // Detect CS rising edge (end of transfer)
            if (!spi_cs_n_prev && spi_cs_n) begin
                transfer_active <= 1'b0;
                rx_data <= rx_shift;
                rx_valid <= 1'b1;
            end
            
            // Sample data on rising edge of SPI clock
            if (transfer_active && spi_clk_rising) begin
                rx_shift <= {rx_shift[6:0], spi_mosi};
                if (bit_count == 0)
                    bit_count <= 3'h7;
                else
                    bit_count <= bit_count - 1;
            end
        end
    end
endmodule