//SystemVerilog
module UART_CRC_Check #(
    parameter CRC_WIDTH = 16,
    parameter POLYNOMIAL = 16'h1021
)(
    input wire clk,
    input wire tx_start,
    input wire tx_active,
    input wire rx_start,
    input wire rx_active,
    input wire rxd,
    input wire [CRC_WIDTH-1:0] rx_crc,
    output reg crc_error,
    input wire [CRC_WIDTH-1:0] crc_seed
);

// 发送CRC生成
reg [CRC_WIDTH-1:0] crc_reg;
reg [CRC_WIDTH-1:0] crc_reg_next;

always @(*) begin
    if (tx_start)
        crc_reg_next = crc_seed;
    else if (tx_active)
        crc_reg_next = (crc_reg << 1) ^ (POLYNOMIAL & {CRC_WIDTH{crc_reg[CRC_WIDTH-1]}});
    else
        crc_reg_next = crc_reg;
end

always @(posedge clk) begin
    crc_reg <= crc_reg_next;
end

// 接收校验单元
reg [CRC_WIDTH-1:0] crc_compare;
reg [CRC_WIDTH-1:0] crc_compare_next;

always @(*) begin
    if (rx_start)
        crc_compare_next = crc_seed;
    else if (rx_active)
        crc_compare_next = (crc_compare << 1) ^ (POLYNOMIAL & {CRC_WIDTH{crc_compare[CRC_WIDTH-1]}} ^ {CRC_WIDTH{rxd}});
    else
        crc_compare_next = crc_compare;
end

always @(posedge clk) begin
    crc_compare <= crc_compare_next;
end

// CRC错误检测
reg crc_error_next;

always @(*) begin
    crc_error_next = (crc_compare_next != rx_crc);
end

always @(posedge clk) begin
    crc_error <= crc_error_next;
end

endmodule