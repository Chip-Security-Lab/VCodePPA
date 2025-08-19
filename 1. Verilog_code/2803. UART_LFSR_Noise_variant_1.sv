//SystemVerilog
module UART_LFSR_Noise #(
    parameter POLY = 16'h8005  // CRC-16 polynomial
)(
    input  wire        clk,
    input  wire        rxd,
    input  wire        parity_bit,
    output reg         noise_detect,
    input  wire        error_inject
);

// Input sampling registers
reg rxd_sampled;
reg parity_bit_sampled;

always @(posedge clk) begin
    rxd_sampled <= rxd;
    parity_bit_sampled <= parity_bit;
end

// LFSR error detection unit
reg [15:0] lfsr_tx;
reg [15:0] lfsr_rx;

wire lfsr_tx_feedback;
wire lfsr_rx_feedback;

assign lfsr_tx_feedback = ^(lfsr_tx & POLY);
assign lfsr_rx_feedback = ^(lfsr_rx & POLY) ^ rxd_sampled;

always @(posedge clk) begin
    lfsr_tx <= {lfsr_tx[14:0], lfsr_tx_feedback};
    lfsr_rx <= {lfsr_rx[14:0], lfsr_rx_feedback};
end

// Noise detection window
reg [2:0] error_samples;
wire error_bit;

assign error_bit = (lfsr_rx[15] != parity_bit_sampled);

// Optimized comparison: 3'b010+1 = 3'b011, so error_samples > 3'b010 <=> MSB is 1
wire error_samples_above_two;
assign error_samples_above_two = error_samples[2];

always @(posedge clk) begin
    error_samples <= {error_samples[1:0], error_bit};
    noise_detect <= error_samples_above_two | error_inject;
end

endmodule