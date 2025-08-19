//SystemVerilog
module spi_variable_width(
    input clk,
    input rst_n,
    input [4:0] data_width, // 1-32 bits
    input [31:0] tx_data,
    input start_tx,
    output reg [31:0] rx_data,
    output reg tx_done,
    output sclk,
    output cs_n,
    output mosi,
    input miso
);

    // Internal Registers and Wires
    reg [31:0] tx_shift_reg_q, rx_shift_reg_q;
    reg [4:0] bit_counter_q;
    reg spi_busy_q, sclk_int_q;
    reg [31:0] rx_data_q;
    reg tx_done_q;

    // Combinational signals
    wire [31:0] tx_shift_reg_d, rx_shift_reg_d;
    wire [4:0] bit_counter_d;
    wire spi_busy_d, sclk_int_d;
    wire [31:0] rx_data_d;
    wire tx_done_d;

    // Internal combinational signals
    wire [31:0] bit_counter_complement;
    wire [31:0] bit_counter_minus_one;
    wire [31:0] tx_shift_reg_next;
    wire [31:0] rx_shift_reg_next;
    wire [4:0] bit_counter_next;
    wire spi_busy_next, sclk_int_next;
    wire tx_done_next;
    wire [31:0] rx_data_next;

    // Output assignments
    assign mosi = tx_shift_reg_q[31];
    assign sclk = spi_busy_q ? sclk_int_q : 1'b0;
    assign cs_n = ~spi_busy_q;

    // Bit counter combinational arithmetic
    assign bit_counter_complement = ~{27'd0, bit_counter_q} + 32'd1;
    assign bit_counter_minus_one = {27'd0, bit_counter_q} + bit_counter_complement;

    // Combinational next-state logic
    assign tx_shift_reg_next =
        (!rst_n)                          ? 32'd0 :
        (start_tx && !spi_busy_q)         ? (tx_data << (32 - data_width)) :
        (spi_busy_q && sclk_int_q)        ? {tx_shift_reg_q[30:0], 1'b0} :
                                            tx_shift_reg_q;

    assign rx_shift_reg_next =
        (!rst_n)                          ? 32'd0 :
        (start_tx && !spi_busy_q)         ? 32'd0 :
        (spi_busy_q && !sclk_int_q)       ? {rx_shift_reg_q[30:0], miso} :
                                            rx_shift_reg_q;

    assign bit_counter_next =
        (!rst_n)                          ? 5'd0 :
        (start_tx && !spi_busy_q)         ? data_width :
        (spi_busy_q && sclk_int_q)        ? bit_counter_minus_one[4:0] :
                                            bit_counter_q;

    assign spi_busy_next =
        (!rst_n)                          ? 1'b0 :
        (start_tx && !spi_busy_q)         ? 1'b1 :
        (spi_busy_q && sclk_int_q && (bit_counter_q == 5'd1)) ? 1'b0 :
                                            spi_busy_q;

    assign sclk_int_next =
        (!rst_n)                          ? 1'b0 :
        (spi_busy_q)                      ? ~sclk_int_q :
                                            1'b0;

    assign tx_done_next =
        (!rst_n)                          ? 1'b0 :
        (start_tx && !spi_busy_q)         ? 1'b0 :
        (spi_busy_q && sclk_int_q && (bit_counter_q == 5'd1)) ? 1'b1 :
        (!spi_busy_q)                     ? 1'b0 :
                                            tx_done_q;

    assign rx_data_next =
        (!rst_n)                          ? 32'd0 :
        (spi_busy_q && sclk_int_q && (bit_counter_q == 5'd1)) ? ((rx_shift_reg_q << 1 | miso) >> (32 - data_width)) :
                                            rx_data_q;

    // Sequential logic for registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift_reg_q <= 32'd0;
            rx_shift_reg_q <= 32'd0;
            bit_counter_q  <= 5'd0;
            spi_busy_q     <= 1'b0;
            sclk_int_q     <= 1'b0;
            rx_data_q      <= 32'd0;
            tx_done_q      <= 1'b0;
        end else begin
            tx_shift_reg_q <= tx_shift_reg_next;
            rx_shift_reg_q <= rx_shift_reg_next;
            bit_counter_q  <= bit_counter_next;
            spi_busy_q     <= spi_busy_next;
            sclk_int_q     <= sclk_int_next;
            rx_data_q      <= rx_data_next;
            tx_done_q      <= tx_done_next;
        end
    end

    // Output assignments from registered signals
    always @(*) begin
        rx_data = rx_data_q;
        tx_done = tx_done_q;
    end

endmodule