//SystemVerilog
module UART_CRC_Check #(
    parameter CRC_WIDTH = 16,
    parameter POLYNOMIAL = 16'h1021
)(
    input  wire                  clk,
    input  wire                  tx_start,
    input  wire                  tx_active,
    input  wire                  rx_start,
    input  wire                  rx_active,
    input  wire                  rxd,
    input  wire [CRC_WIDTH-1:0]  rx_crc,
    output reg                   crc_error,
    input  wire [CRC_WIDTH-1:0]  crc_seed
);

// 前向寄存器重定时优化后的CRC生成器
reg [CRC_WIDTH-1:0] crc_next;
reg [CRC_WIDTH-1:0] crc_reg;

always @(*) begin
    if (tx_start) begin
        crc_next = crc_seed;
    end else if (tx_active) begin
        crc_next = {crc_reg[CRC_WIDTH-2:0], 1'b0} ^ (crc_reg[CRC_WIDTH-1] ? POLYNOMIAL : {CRC_WIDTH{1'b0}});
    end else begin
        crc_next = crc_reg;
    end
end

always @(posedge clk) begin
    crc_reg <= crc_next;
end

// 前向寄存器重定时优化后的CRC比较逻辑
reg [CRC_WIDTH-1:0] crc_compare_next;
reg [CRC_WIDTH-1:0] crc_compare_reg;
reg [CRC_WIDTH-1:0] crc_compare_buf1;

always @(*) begin
    if (rx_start) begin
        crc_compare_next = crc_seed;
    end else if (rx_active) begin
        crc_compare_next = {crc_compare_reg[CRC_WIDTH-2:0], rxd} ^ (crc_compare_reg[CRC_WIDTH-1] ? POLYNOMIAL : {CRC_WIDTH{1'b0}});
    end else begin
        crc_compare_next = crc_compare_reg;
    end
end

always @(posedge clk) begin
    crc_compare_reg <= crc_compare_next;
    crc_compare_buf1 <= crc_compare_next;
end

// 二级缓冲由组合逻辑和寄存器前移实现
reg [CRC_WIDTH-1:0] crc_compare_buf2;

always @(posedge clk) begin
    crc_compare_buf2 <= crc_compare_buf1;
end

always @(posedge clk) begin
    crc_error <= (crc_compare_buf2 ^ rx_crc) != {CRC_WIDTH{1'b0}};
end

endmodule