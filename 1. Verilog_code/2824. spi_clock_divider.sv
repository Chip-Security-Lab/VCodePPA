module spi_clock_divider #(
    parameter SYS_CLK_FREQ = 50_000_000,
    parameter DEFAULT_SPI_CLK = 1_000_000
)(
    input sys_clk, sys_rst_n,
    input [31:0] clk_divider, // 0 means use default
    input [7:0] tx_data,
    input start,
    output reg [7:0] rx_data,
    output reg busy, done,
    
    output reg spi_clk,
    output reg spi_cs_n,
    output spi_mosi,
    input spi_miso
);
    localparam DEFAULT_DIV = SYS_CLK_FREQ / (2 * DEFAULT_SPI_CLK);
    
    reg [31:0] clk_counter;
    reg [31:0] active_divider;
    reg [7:0] tx_shift, rx_shift;
    reg [2:0] bit_count;
    
    assign spi_mosi = tx_shift[7];
    
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            clk_counter <= 32'd0;
            active_divider <= DEFAULT_DIV;
            tx_shift <= 8'd0;
            rx_shift <= 8'd0;
            bit_count <= 3'd0;
            busy <= 1'b0;
            done <= 1'b0;
            spi_clk <= 1'b0;
            spi_cs_n <= 1'b1;
        end else if (start && !busy) begin
            active_divider <= (clk_divider == 0) ? DEFAULT_DIV : clk_divider;
            tx_shift <= tx_data;
            bit_count <= 3'd7;
            busy <= 1'b1;
            done <= 1'b0;
            spi_cs_n <= 1'b0;
            clk_counter <= 32'd0;
        end else if (busy) begin
            if (clk_counter >= active_divider-1) begin
                clk_counter <= 32'd0;
                spi_clk <= ~spi_clk;
                
                if (spi_clk) begin // Falling edge
                    if (bit_count == 0) begin
                        busy <= 1'b0;
                        done <= 1'b1;
                        rx_data <= {rx_shift[6:0], spi_miso};
                        spi_cs_n <= 1'b1;
                    end else begin
                        tx_shift <= {tx_shift[6:0], 1'b0};
                        bit_count <= bit_count - 1;
                    end
                end else // Rising edge
                    rx_shift <= {rx_shift[6:0], spi_miso};
            end else
                clk_counter <= clk_counter + 1;
        end else
            done <= 1'b0;
    end
endmodule