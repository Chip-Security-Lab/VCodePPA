//SystemVerilog
module UART_LFSR_Noise #(
    parameter POLY = 16'h8005 // CRC-16 polynomial
)(
    input wire clk,               // Clock input
    input wire rxd,               // Received data input
    input wire parity_bit,        // Parity bit input
    output reg noise_detect,      // Noise detection output
    input wire error_inject       // Error injection for testing
);

// LFSR registers for TX and RX
reg [15:0] lfsr_tx_reg, lfsr_rx_reg;

// Registered input signals for retiming
reg rxd_reg;
reg parity_bit_reg;

// Precompute feedback for LFSR update to reduce critical path
wire lfsr_tx_feedback;
wire lfsr_rx_feedback;

assign lfsr_tx_feedback = ^(lfsr_tx_reg & POLY);
assign lfsr_rx_feedback = ^(lfsr_rx_reg & POLY) ^ rxd_reg;

// Move registers after combinational logic for retiming
always @(posedge clk) begin
    rxd_reg <= rxd;
    parity_bit_reg <= parity_bit;
end

always @(posedge clk) begin
    lfsr_tx_reg <= {lfsr_tx_reg[14:0], lfsr_tx_feedback};
    lfsr_rx_reg <= {lfsr_rx_reg[14:0], lfsr_rx_feedback};
end

// Noise detection window
reg [2:0] error_samples_reg;

// Precompute error condition to balance path
wire parity_error;
assign parity_error = lfsr_rx_reg[15] ^ parity_bit_reg;

// Precompute majority function for error_samples to balance path
wire error_samples_majority;
assign error_samples_majority = (error_samples_reg[2] & error_samples_reg[1]) |
                               (error_samples_reg[2] & error_samples_reg[0]) |
                               (error_samples_reg[1] & error_samples_reg[0]);

always @(posedge clk) begin
    error_samples_reg <= {error_samples_reg[1:0], parity_error};
    noise_detect <= error_samples_majority | error_inject;
end

endmodule