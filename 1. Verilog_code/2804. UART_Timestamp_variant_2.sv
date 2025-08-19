//SystemVerilog
module UART_Timestamp #(
    parameter TS_WIDTH = 32,
    parameter TS_CLK_HZ = 100_000_000
)(
    input wire clk,
    input wire rx_start,
    input wire tx_start,
    output reg [TS_WIDTH-1:0] rx_timestamp,
    output reg [TS_WIDTH-1:0] tx_timestamp,
    input wire ts_sync
);

    // Internal signal declarations
    reg [TS_WIDTH-1:0] global_counter_reg;
    wire [TS_WIDTH-1:0] global_counter_next;
    wire [TS_WIDTH-1:0] rx_timestamp_comb;
    wire [TS_WIDTH-1:0] tx_timestamp_comb;

    // Global counter combinational logic
    assign global_counter_next = ts_sync ? {TS_WIDTH{1'b0}} : global_counter_reg + 1'b1;

    // Timestamp capture combinational logic
    assign rx_timestamp_comb = rx_start ? global_counter_reg : rx_timestamp;
    assign tx_timestamp_comb = tx_start ? global_counter_reg : tx_timestamp;

    // Global counter sequential logic
    always @(posedge clk) begin
        global_counter_reg <= global_counter_next;
    end

    // Timestamp sequential logic
    always @(posedge clk) begin
        rx_timestamp <= rx_timestamp_comb;
        tx_timestamp <= tx_timestamp_comb;
    end

    parameter TS_CLK_DIVIDEND = 1_000_000;
    parameter TS_CLK_DIVISOR = TS_CLK_HZ / TS_CLK_DIVIDEND;

endmodule