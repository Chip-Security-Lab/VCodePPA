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
    reg  [7:0] rx_shift_reg, tx_shift_reg;
    reg  [2:0] bit_count;
    reg        sclk_meta, sclk_sync;
    wire       sclk_rising, sclk_falling;
    wire       is_last_bit, is_first_bit;

    // Double-flop synchronizer for SCLK
    always @(posedge clk_i) begin
        sclk_meta <= sclk_i;
        sclk_sync <= sclk_meta;
    end

    assign sclk_rising  =  (sclk_meta & ~sclk_sync);
    assign sclk_falling = (~sclk_meta &  sclk_sync);
    assign miso_o       =  tx_shift_reg[7];

    assign is_last_bit  = (bit_count[2:1] == 2'b11) & (bit_count[0] == 1'b1); // 3'd7
    assign is_first_bit = ~(|bit_count); // 3'd0

    always @(posedge clk_i) begin
        if (rst_i) begin
            rx_shift_reg <= 8'b0;
            tx_shift_reg <= 8'b0;
            bit_count    <= 3'b0;
            rx_valid     <= 1'b0;
            rx_data      <= 8'b0;
        end else if (~cs_n_i) begin
            if (sclk_rising) begin
                rx_shift_reg <= {rx_shift_reg[6:0], mosi_i};
                bit_count    <= bit_count + 3'b1;
                rx_valid     <= is_last_bit;
                if (is_last_bit)
                    rx_data <= {rx_shift_reg[6:0], mosi_i};
            end else begin
                rx_valid <= 1'b0;
            end

            if (sclk_falling) begin
                tx_shift_reg <= is_first_bit ? tx_data : {tx_shift_reg[6:0], 1'b0};
            end
        end else begin
            rx_valid <= 1'b0;
        end
    end
endmodule