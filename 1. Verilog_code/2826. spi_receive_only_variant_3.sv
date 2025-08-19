//SystemVerilog
module spi_receive_only(
    input  wire        spi_clk,
    input  wire        spi_cs_n,
    input  wire        spi_mosi,
    input  wire        sys_clk,
    input  wire        sys_rst_n,
    output reg  [7:0]  rx_data,
    output reg         rx_valid
);

    reg  [7:0] rx_shift_reg;
    reg  [2:0] bit_counter;
    reg        cs_n_prev;
    reg        transfer_en;
    reg  [1:0] spi_clk_sync;

    wire       spi_clk_rising_edge;

    // 补码加法实现减法：bit_counter - 3'd1 替换为 bit_counter + (~3'd1 + 1'b1)
    wire [2:0] one_complement     = ~3'd1;
    wire [2:0] two_complement_one = one_complement + 3'd1;
    wire [2:0] next_bit_counter   = (bit_counter == 3'd0) ? 3'd7 : (bit_counter + two_complement_one);

    // Synchronize SPI clock to system clock domain
    always @(posedge sys_clk) begin
        spi_clk_sync <= {spi_clk_sync[0], spi_clk};
    end

    assign spi_clk_rising_edge = spi_clk_sync[0] & ~spi_clk_sync[1];

    // Separate CS edge detection logic for path balancing
    wire cs_falling_edge = cs_n_prev & ~spi_cs_n;
    wire cs_rising_edge  = ~cs_n_prev & spi_cs_n;

    // Main sequential logic block
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            rx_shift_reg   <= 8'h00;
            bit_counter    <= 3'd0;
            rx_data        <= 8'h00;
            rx_valid       <= 1'b0;
            cs_n_prev      <= 1'b1;
            transfer_en    <= 1'b0;
        end else begin
            cs_n_prev  <= spi_cs_n;

            // Balanced: update transfer enable and bit counter using edge signals
            transfer_en <= (cs_falling_edge) ? 1'b1 : (cs_rising_edge ? 1'b0 : transfer_en);

            // Balanced: handle rx_valid and rx_data using cs rising edge
            rx_valid   <= cs_rising_edge;
            rx_data    <= cs_rising_edge ? rx_shift_reg : rx_data;

            // Balanced: sample data and update shift register and bit counter
            if (transfer_en & spi_clk_rising_edge) begin
                rx_shift_reg <= {rx_shift_reg[6:0], spi_mosi};
                bit_counter  <= next_bit_counter;
            end else if (cs_falling_edge) begin
                bit_counter  <= 3'd7;
            end
        end
    end

endmodule