//SystemVerilog
module spi_with_parity(
    input        clk,
    input        rst_n,
    input  [7:0] tx_data,
    input        tx_start,
    output [7:0] rx_data,
    output       rx_done,
    output       parity_error,
    output       sclk,
    output       ss_n,
    output       mosi,
    input        miso
);

    reg  [8:0] tx_shift_reg; // 8 data bits + 1 parity bit
    reg  [8:0] rx_shift_reg;
    reg  [3:0] bit_counter;
    reg        busy_flag;
    reg        done_flag;
    reg        sclk_reg;

    // Even parity bit calculation for transmission
    wire tx_parity_bit = ^tx_data;

    assign sclk  = busy_flag & sclk_reg;
    assign ss_n  = ~busy_flag;
    assign mosi  = tx_shift_reg[8];
    assign rx_data = rx_shift_reg[7:0];
    assign rx_done = done_flag;

    // Parity error detection: even parity
    assign parity_error = done_flag & ((^rx_shift_reg[7:0]) ^ rx_shift_reg[8]);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift_reg <= 9'b0;
            rx_shift_reg <= 9'b0;
            bit_counter  <= 4'b0;
            busy_flag    <= 1'b0;
            done_flag    <= 1'b0;
            sclk_reg     <= 1'b0;
        end else begin
            // Priority: Start > Busy > Idle
            if (tx_start & ~busy_flag) begin
                tx_shift_reg <= {tx_data, tx_parity_bit};
                rx_shift_reg <= 9'b0;
                bit_counter  <= 4'd9;
                busy_flag    <= 1'b1;
                done_flag    <= 1'b0;
                sclk_reg     <= 1'b0;
            end else if (busy_flag) begin
                sclk_reg <= ~sclk_reg;
                if (!sclk_reg) begin // Rising edge: sample MISO, decrement counter if in valid range
                    rx_shift_reg <= {rx_shift_reg[7:0], miso};
                    if (bit_counter != 4'd0)
                        bit_counter <= bit_counter - 4'd1;
                end else begin // Falling edge: shift out next MOSI bit and check for end
                    tx_shift_reg <= {tx_shift_reg[7:0], 1'b0};
                    if (bit_counter == 4'd1) begin
                        busy_flag <= 1'b0;
                        done_flag <= 1'b1;
                    end
                end
            end else begin
                done_flag <= 1'b0;
            end
        end
    end

endmodule