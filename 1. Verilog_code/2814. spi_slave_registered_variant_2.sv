//SystemVerilog
module spi_slave_registered (
    input  wire        clk_i,
    input  wire        rst_i,
    input  wire        sclk_i,
    input  wire        cs_n_i,
    input  wire        mosi_i,
    output wire        miso_o,
    output reg  [7:0]  rx_data,
    input  wire [7:0]  tx_data,
    output reg         rx_valid
);
    reg  [7:0] rx_shift_reg;
    reg  [7:0] tx_shift_reg;
    reg  [2:0] bit_count;
    reg        sclk_r;
    reg        sclk_r2;
    wire       sclk_rising;
    wire       sclk_falling;

    // Edge detection
    always @(posedge clk_i) begin
        sclk_r  <= sclk_i;
        sclk_r2 <= sclk_r;
    end

    assign sclk_rising  =  sclk_r & ~sclk_r2;
    assign sclk_falling = ~sclk_r &  sclk_r2;
    assign miso_o = tx_shift_reg[7];

    // Simplified 3-bit Adder for bit_count increment (bit_count_next = bit_count + 1)
    wire [2:0] bit_count_next;
    assign bit_count_next = bit_count + 3'b001;

    always @(posedge clk_i) begin
        if (rst_i) begin
            rx_shift_reg <= 8'h00;
            tx_shift_reg <= 8'h00;
            bit_count    <= 3'h0;
            rx_valid     <= 1'b0;
            rx_data      <= 8'h00;
        end else if (!cs_n_i) begin
            if (sclk_rising) begin
                rx_shift_reg <= {rx_shift_reg[6:0], mosi_i};
                bit_count    <= bit_count_next;
                rx_valid     <= (bit_count == 3'h7);
                if (bit_count == 3'h7)
                    rx_data <= {rx_shift_reg[6:0], mosi_i};
            end
            if (sclk_falling && bit_count == 3'h0) begin
                tx_shift_reg <= tx_data;
            end else if (sclk_falling) begin
                tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
            end
        end else begin
            rx_valid <= 1'b0;
        end
    end
endmodule