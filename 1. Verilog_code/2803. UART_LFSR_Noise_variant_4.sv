//SystemVerilog
module UART_LFSR_Noise #(
    parameter POLY = 16'h8005  // CRC-16 Polynomial
)(
    input wire clk,                 // Clock input
    input wire rxd,                 // Receive data input
    input wire parity_bit,          // Parity bit input
    output reg noise_detect,
    input wire error_inject         // Error injection for testing
);

// 前向寄存器重定时：将输入采样寄存器移至组合逻辑之后

// LFSR寄存器
reg [15:0] lfsr_tx, lfsr_rx;

// LFSR反馈信号
wire lfsr_tx_feedback;
wire lfsr_rx_feedback;

// 直接使用输入信号进行LFSR反馈计算，寄存器推移到组合逻辑后
assign lfsr_tx_feedback = ^(lfsr_tx & POLY);
assign lfsr_rx_feedback = ^(lfsr_rx & POLY) ^ rxd;

// LFSR更新逻辑
always @(posedge clk) begin
    lfsr_tx <= {lfsr_tx[14:0], lfsr_tx_feedback};
    lfsr_rx <= {lfsr_rx[14:0], lfsr_rx_feedback};
end

// Parity bit采样寄存器，推移到组合逻辑后
reg parity_bit_q;
always @(posedge clk) begin
    parity_bit_q <= parity_bit;
end

// 噪声检测窗口
reg [2:0] error_samples;
wire error_sample;

// 直接使用组合逻辑后的信号
assign error_sample = (lfsr_rx[15] != parity_bit_q);

always @(posedge clk) begin
    error_samples <= {error_samples[1:0], error_sample};
    noise_detect <= (error_samples > 3'b010) | error_inject;
end

endmodule