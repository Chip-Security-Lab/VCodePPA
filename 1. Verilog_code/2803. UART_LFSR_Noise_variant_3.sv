//SystemVerilog
module UART_LFSR_Noise #(
    parameter POLY = 16'h8005  // CRC-16 Polynomial
)(
    input wire clk,
    input wire rxd,
    input wire parity_bit,
    output reg noise_detect,
    input wire error_inject
);

// Stage 1: Input Sampling
reg rxd_stage1;
reg parity_bit_stage1;

always @(posedge clk) begin
    rxd_stage1 <= rxd;
    parity_bit_stage1 <= parity_bit;
end

// Stage 2: LFSR Next Value Calculation
reg [15:0] lfsr_tx_stage2, lfsr_rx_stage2;
reg lfsr_tx_next_stage2;
reg lfsr_rx_next_stage2;

always @(posedge clk) begin
    lfsr_tx_stage2 <= lfsr_tx_stage2;
    lfsr_rx_stage2 <= lfsr_rx_stage2;
    lfsr_tx_next_stage2 <= ^(lfsr_tx_stage2 & POLY);
    lfsr_rx_next_stage2 <= ^(lfsr_rx_stage2 & POLY) ^ rxd_stage1;
end

// Stage 3: LFSR Update
reg [15:0] lfsr_tx_stage3, lfsr_rx_stage3;

always @(posedge clk) begin
    lfsr_tx_stage3 <= {lfsr_tx_stage2[14:0], lfsr_tx_next_stage2};
    lfsr_rx_stage3 <= {lfsr_rx_stage2[14:0], lfsr_rx_next_stage2};
end

// Stage 4: Parity Mismatch Detection
reg parity_mismatch_stage4;

always @(posedge clk) begin
    parity_mismatch_stage4 <= (lfsr_rx_stage3[15] != parity_bit_stage1);
end

// Stage 5: Error Sampling and Noise Detection
reg [2:0] error_samples_stage5;
reg parity_mismatch_reg_stage5;

always @(posedge clk) begin
    parity_mismatch_reg_stage5 <= parity_mismatch_stage4;
    error_samples_stage5 <= {error_samples_stage5[1:0], parity_mismatch_reg_stage5};
    noise_detect <= (error_samples_stage5 > 3'b010) | error_inject;
end

// LFSR Initialization on Reset (optional, uncomment if reset is required)
// initial begin
//     lfsr_tx_stage2 = 16'h1;
//     lfsr_rx_stage2 = 16'h1;
// end

// For proper operation, ensure lfsr_tx_stage2/lfsr_rx_stage2 are initialized externally or via reset if needed

endmodule