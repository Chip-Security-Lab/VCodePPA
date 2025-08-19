//SystemVerilog
module QSPI_Quad_Mode #(
    parameter DDR_EN = 0
)(
    inout [3:0] io,
    input wire sck,
    input ddr_clk,
    output reg [31:0] rx_fifo,
    input [1:0] mode // 00:SPI, 01:dual, 10:quad
);

// 前向寄存器重定时：将输入io的采样寄存器推移到组合逻辑后
reg [3:0] io_dir_reg;
reg [3:0] tx_data_reg;
reg [3:0] rx_data_reg;
reg [3:0] io_in_reg;

// 组合逻辑决定io_dir和tx_data
wire [3:0] io_dir_next;
wire [3:0] tx_data_next;

assign io_dir_next = (mode == 2'b00) ? 4'b0001 :
                     (mode == 2'b01) ? 4'b0011 :
                     (mode == 2'b10) ? 4'b1111 :
                     4'b0000;

// 采样io输入，前向推移寄存器
always @(posedge sck) begin
    io_in_reg <= io;
end

// 组合逻辑决定rx_data_next
wire [3:0] rx_data_next;
assign rx_data_next = (mode == 2'b00) ? {3'b000, io_in_reg[1]} :
                      (mode == 2'b01) ? {2'b00, io_in_reg[1:0]} :
                      (mode == 2'b10) ? io_in_reg :
                      4'b0000;

// io_dir寄存器推移到组合逻辑后
always @(posedge sck) begin
    io_dir_reg <= io_dir_next;
    rx_data_reg <= rx_data_next;
end

// rx_fifo寄存器位置保持
always @(posedge sck) begin
    if (mode == 2'b10) begin
        rx_fifo <= {rx_fifo[27:0], rx_data_reg};
    end
end

// 三态IO输出控制
assign io[0] = (io_dir_reg[0]) ? tx_data_reg[0] : 1'bz;
assign io[1] = (io_dir_reg[1]) ? tx_data_reg[1] : 1'bz;
assign io[2] = (io_dir_reg[2]) ? tx_data_reg[2] : 1'bz;
assign io[3] = (io_dir_reg[3]) ? tx_data_reg[3] : 1'bz;

endmodule