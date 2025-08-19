//SystemVerilog
module spi_with_parity(
    input clk, rst_n,
    input [7:0] tx_data,
    input tx_start,
    output [7:0] rx_data,
    output rx_done,
    output parity_error,
    output sclk,
    output ss_n,
    output mosi,
    input miso
);
    reg [8:0] tx_shift_reg; // 8 data bits + 1 parity bit
    reg [8:0] rx_shift_reg;
    reg [3:0] bit_count_reg;
    reg busy_reg;
    reg sclk_reg;

    reg done_reg_q;
    reg [8:0] rx_shift_reg_q;

    wire tx_parity_wire = ^tx_data; // Calculated parity bit

    // Main SPI logic with retimed registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift_reg <= 9'h000;
            rx_shift_reg <= 9'h000;
            bit_count_reg <= 4'h0;
            busy_reg <= 1'b0;
            done_reg_q <= 1'b0;
            rx_shift_reg_q <= 9'h000;
            sclk_reg <= 1'b0;
        end else if (tx_start && !busy_reg) begin
            // Move register after parity calculation and muxing logic
            tx_shift_reg <= {tx_data, tx_parity_wire};
            bit_count_reg <= 4'd9;
            busy_reg <= 1'b1;
            done_reg_q <= 1'b0;
            rx_shift_reg <= 9'h000;
            rx_shift_reg_q <= 9'h000;
            sclk_reg <= 1'b0;
        end else if (busy_reg) begin
            sclk_reg <= ~sclk_reg;
            if (sclk_reg) begin // Falling edge
                tx_shift_reg <= {tx_shift_reg[7:0], 1'b0};
                if (bit_count_reg == 4'd0) begin
                    busy_reg <= 1'b0;
                    done_reg_q <= 1'b1;
                    rx_shift_reg_q <= rx_shift_reg;
                end
            end else begin // Rising edge
                rx_shift_reg <= {rx_shift_reg[7:0], miso};
                bit_count_reg <= bit_count_reg - 4'd1;
            end
        end else begin
            done_reg_q <= 1'b0;
        end
    end

    assign sclk = busy_reg ? sclk_reg : 1'b0;
    assign ss_n = ~busy_reg;
    assign mosi = tx_shift_reg[8];
    assign rx_data = rx_shift_reg_q[7:0];
    assign rx_done = done_reg_q;
    assign parity_error = done_reg_q & ((^rx_shift_reg_q[7:0]) != rx_shift_reg_q[8]);
endmodule