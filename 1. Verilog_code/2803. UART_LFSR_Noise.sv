module UART_LFSR_Noise #(
    parameter POLY = 16'h8005  // CRC-16多项式
)(
    input wire clk,          // 添加时钟输入
    input wire rxd,          // 添加接收数据输入
    input wire parity_bit,   // 添加奇偶校验位输入
    output reg noise_detect,
    input wire error_inject  // 测试用错误注入
);
// LFSR错误检测单元
reg [15:0] lfsr_tx, lfsr_rx;

always @(posedge clk) begin
    // 发送端LFSR更新
    lfsr_tx <= {lfsr_tx[14:0], ^(lfsr_tx & POLY)};
    // 接收端LFSR验证
    lfsr_rx <= {lfsr_rx[14:0], ^(lfsr_rx & POLY) ^ rxd};
end

// 噪声检测窗口
reg [2:0] error_samples;
always @(posedge clk) begin
    error_samples <= {error_samples[1:0], (lfsr_rx[15] != parity_bit)};
    noise_detect <= (error_samples > 3'b010) | error_inject;
end
endmodule