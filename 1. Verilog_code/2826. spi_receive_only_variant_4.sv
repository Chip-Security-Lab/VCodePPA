//SystemVerilog
module spi_receive_only(
    input        spi_clk,
    input        spi_cs_n,
    input        spi_mosi,
    input        sys_clk,
    input        sys_rst_n,
    output reg [7:0] rx_data,
    output reg       rx_valid
);
    reg [7:0] shift_reg;
    reg [2:0] bit_cnt;
    reg       cs_n_sync_d, spi_transfer_en;
    reg [1:0] spi_clk_sync;

    wire spi_clk_posedge = spi_clk_sync[0] & ~spi_clk_sync[1];
    wire cs_n_fall = cs_n_sync_d & ~spi_cs_n;
    wire cs_n_rise = ~cs_n_sync_d & spi_cs_n;

    // Synchronize SPI clock to system clock domain
    always @(posedge sys_clk) begin
        spi_clk_sync <= {spi_clk_sync[0], spi_clk};
    end

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            shift_reg        <= 8'h00;
            bit_cnt          <= 3'd0;
            rx_data          <= 8'h00;
            rx_valid         <= 1'b0;
            cs_n_sync_d      <= 1'b1;
            spi_transfer_en  <= 1'b0;
        end else begin
            cs_n_sync_d <= spi_cs_n;
            rx_valid    <= 1'b0;

            // Start of transfer: CSN falling edge
            if (cs_n_fall) begin
                spi_transfer_en <= 1'b1;
                bit_cnt         <= 3'd7;
            end

            // End of transfer: CSN rising edge
            if (cs_n_rise) begin
                spi_transfer_en <= 1'b0;
                rx_data         <= shift_reg;
                rx_valid        <= 1'b1;
            end

            // Sample data on SPI clock rising edge when transfer enabled
            if (spi_transfer_en && spi_clk_posedge) begin
                shift_reg <= {shift_reg[6:0], spi_mosi};
                bit_cnt   <= (|bit_cnt) ? (bit_cnt - 3'd1) : 3'd7;
            end
        end
    end
endmodule