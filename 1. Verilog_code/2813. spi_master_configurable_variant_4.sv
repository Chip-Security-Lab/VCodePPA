//SystemVerilog
module spi_master_configurable (
    input wire clock, reset,
    input wire cpol, cpha,
    input wire enable, load,
    input wire [7:0] tx_data,
    output wire [7:0] rx_data,
    output wire spi_clk, spi_mosi,
    input wire spi_miso,
    output wire cs_n, tx_ready
);
    reg [7:0] tx_shift_reg, rx_shift_reg;
    reg [3:0] bit_count;
    reg sclk_int, tx_ready_reg;

    assign spi_clk = (cpol ^ sclk_int);
    assign spi_mosi = tx_shift_reg[7];
    assign rx_data = rx_shift_reg;
    assign tx_ready = tx_ready_reg;
    assign cs_n = ~enable;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            bit_count <= 4'd0;
            tx_ready_reg <= 1'b1;
            sclk_int <= 1'b0;
            tx_shift_reg <= 8'h00;
            rx_shift_reg <= 8'h00;
        end else begin
            case ({load & tx_ready_reg, ~tx_ready_reg})
                2'b10: begin // Load new data
                    tx_shift_reg <= tx_data;
                    tx_ready_reg <= 1'b0;
                    bit_count <= 4'd8;
                end
                2'b01: begin // SPI transfer in progress
                    sclk_int <= ~sclk_int;
                    case ({sclk_int ^ cpha, ~(sclk_int ^ cpha)})
                        2'b10: begin // Sample MISO (rx)
                            rx_shift_reg <= {rx_shift_reg[6:0], spi_miso};
                        end
                        2'b01: begin // Shift MOSI (tx)
                            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                            bit_count <= bit_count - 4'd1;
                            if (bit_count == 4'd1)
                                tx_ready_reg <= 1'b1;
                        end
                        default: ;
                    endcase
                end
                default: ;
            endcase
        end
    end
endmodule