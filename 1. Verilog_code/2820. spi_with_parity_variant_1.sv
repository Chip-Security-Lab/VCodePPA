//SystemVerilog
module spi_with_parity(
    input         clk,
    input         rst_n,
    input  [7:0]  tx_data,
    input         tx_start,
    output [7:0]  rx_data,
    output        rx_done,
    output        parity_error,
    output        sclk,
    output        ss_n,
    output        mosi,
    input         miso
);
// Internal shift registers and state
reg  [8:0] tx_shift_reg;
reg  [8:0] rx_shift_reg;
reg  [3:0] bit_count_reg;
reg        busy_reg;
reg        done_reg;
reg        sclk_reg;

// Buffering high fanout signals
reg  [8:0] rx_shift_buf1, rx_shift_buf2; // Two-stage buffer for rx_shift
reg        b0_buf1, b0_buf2;             // Two-stage buffer for b0

// Parity calculation
wire       tx_parity_wire = ^tx_data;

// Assignments
assign sclk         = busy_reg ? sclk_reg : 1'b0;
assign ss_n         = ~busy_reg;
assign mosi         = tx_shift_reg[8];
assign rx_data      = rx_shift_buf2[7:0];
assign rx_done      = done_reg;
assign parity_error = done_reg & ((^rx_shift_buf2[7:0]) != rx_shift_buf2[8]);

// Buffer for rx_shift: two-stage register tree
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_shift_buf1 <= 9'h000;
        rx_shift_buf2 <= 9'h000;
    end else begin
        rx_shift_buf1 <= rx_shift_reg;
        rx_shift_buf2 <= rx_shift_buf1;
    end
end

// Buffer for b0 (bit_count_reg[0]): two-stage register tree
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        b0_buf1 <= 1'b0;
        b0_buf2 <= 1'b0;
    end else begin
        b0_buf1 <= bit_count_reg[0];
        b0_buf2 <= b0_buf1;
    end
end

// Optimized SPI logic with parity and efficient comparison
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_shift_reg  <= 9'h000;
        rx_shift_reg  <= 9'h000;
        bit_count_reg <= 4'h0;
        busy_reg      <= 1'b0;
        done_reg      <= 1'b0;
        sclk_reg      <= 1'b0;
    end else if (tx_start && !busy_reg) begin
        tx_shift_reg  <= {tx_data, tx_parity_wire};
        bit_count_reg <= 4'd9;
        busy_reg      <= 1'b1;
        done_reg      <= 1'b0;
    end else if (busy_reg) begin
        sclk_reg <= ~sclk_reg;
        if (sclk_reg) begin // Falling edge
            tx_shift_reg <= {tx_shift_reg[7:0], 1'b0};
            if (bit_count_reg[3:0] == 4'd0) begin
                busy_reg <= 1'b0;
                done_reg <= 1'b1;
            end
        end else begin // Rising edge
            rx_shift_reg  <= {rx_shift_reg[7:0], miso};
            // Avoid underflow and unnecessary subtraction using range check
            if (bit_count_reg != 4'd0)
                bit_count_reg <= bit_count_reg - 4'd1;
        end
    end
end

endmodule