//SystemVerilog
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

    reg [7:0] tx_shift_reg, rx_shift_reg;
    reg [7:0] tx_data_reg;
    reg [3:0] bit_count_reg;
    reg sclk_reg, ready_reg;

    wire sclk_toggle;
    wire sampling_edge, shifting_edge;

    // Combination logic for edges (based on CPHA and sclk)
    assign sampling_edge = ( (sclk_reg && ~cpha) || (~sclk_reg && cpha) );
    assign shifting_edge = ( (~sclk_reg && ~cpha) || (sclk_reg && cpha) );
    assign sclk_toggle   = ~sclk_reg;

    // SPI outputs
    assign spi_clk   = (cpol) ? ~sclk_reg : sclk_reg;
    assign spi_mosi  = tx_shift_reg[7];
    assign rx_data   = rx_shift_reg;
    assign tx_ready  = ready_reg;
    assign cs_n      = ~enable;

    // Forward register retiming: move tx_data_reg after load logic
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            tx_data_reg   <= 8'h00;
        end else if (load && ready_reg) begin
            tx_data_reg   <= tx_data;
        end
    end

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            tx_shift_reg  <= 8'h00;
            rx_shift_reg  <= 8'h00;
            bit_count_reg <= 4'd0;
            sclk_reg      <= 1'b0;
            ready_reg     <= 1'b1;
        end else if (load && ready_reg) begin
            tx_shift_reg  <= tx_data_reg;
            ready_reg     <= 1'b0;
            bit_count_reg <= 4'd8;
            sclk_reg      <= cpol; // Initialize sclk based on CPOL for proper phasing
        end else if (~ready_reg) begin
            sclk_reg <= sclk_toggle;
            if (sampling_edge) begin
                rx_shift_reg <= {rx_shift_reg[6:0], spi_miso};
            end
            if (shifting_edge) begin
                tx_shift_reg  <= {tx_shift_reg[6:0], 1'b0};
                bit_count_reg <= bit_count_reg - 4'd1;
                if (bit_count_reg == 4'd1)
                    ready_reg <= 1'b1;
            end
        end
    end

endmodule