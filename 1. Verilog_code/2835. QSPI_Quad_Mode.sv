module QSPI_Quad_Mode #(
    parameter DDR_EN = 0
)(
    inout [3:0] io,
    input wire sck,        // 添加时钟输入
    input ddr_clk,
    output reg [31:0] rx_fifo,
    input [1:0] mode // 00:SPI, 01:dual, 10:quad
);

reg [3:0] io_dir;
reg [3:0] tx_data;
reg [3:0] rx_data;

// 完整的四线IO三态控制
assign io[0] = (io_dir[0]) ? tx_data[0] : 1'bz;
assign io[1] = (io_dir[1]) ? tx_data[1] : 1'bz;
assign io[2] = (io_dir[2]) ? tx_data[2] : 1'bz;
assign io[3] = (io_dir[3]) ? tx_data[3] : 1'bz;

always @(posedge sck) begin
    case(mode)
    2'b00: begin
        // 标准SPI模式
        io_dir <= 4'b0001; // 只有MOSI为输出
        rx_data[0] <= io[1]; // MISO读取
    end
    2'b01: begin
        // 双线模式
        io_dir <= 4'b0011; // MOSI和MISO都可以作为输出
        rx_data[1:0] <= io[1:0];
    end
    2'b10: begin
        // 四线模式
        io_dir <= 4'b1111; // 全部作为输出
        rx_data <= io;
        rx_fifo <= {rx_fifo[27:0], rx_data};
    end
    default: io_dir <= 4'b0000;
    endcase
end
endmodule