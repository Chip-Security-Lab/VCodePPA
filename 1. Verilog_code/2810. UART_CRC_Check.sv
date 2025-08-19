module UART_CRC_Check #(
    parameter CRC_WIDTH = 16,
    parameter POLYNOMIAL = 16'h1021
)(
    input wire clk,             // 添加时钟输入
    input wire tx_start,        // 添加发送开始信号
    input wire tx_active,       // 添加发送激活信号
    input wire rx_start,        // 添加接收开始信号
    input wire rx_active,       // 添加接收激活信号
    input wire rxd,             // 添加接收数据输入
    input wire [CRC_WIDTH-1:0] rx_crc, // 添加接收CRC输入
    output reg crc_error,
    input wire [CRC_WIDTH-1:0] crc_seed
);
// CRC生成器
reg [CRC_WIDTH-1:0] crc_reg;

always @(posedge clk) begin
    if (tx_start)
        crc_reg <= crc_seed;
    else if (tx_active)
        crc_reg <= (crc_reg << 1) ^ (POLYNOMIAL & {16{crc_reg[15]}});
end

// 接收校验单元
reg [CRC_WIDTH-1:0] crc_compare;
always @(posedge clk) begin
    if (rx_start)
        crc_compare <= crc_seed;
    else if (rx_active)
        crc_compare <= (crc_compare << 1) ^ (POLYNOMIAL & {16{crc_compare[15]}} ^ {16{rxd}});

    crc_error <= (crc_compare != rx_crc);
end
endmodule