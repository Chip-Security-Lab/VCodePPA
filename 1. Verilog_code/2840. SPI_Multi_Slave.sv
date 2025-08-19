module SPI_Multi_Slave #(
    parameter SLAVES = 4,
    parameter DECODE_WIDTH = 2
)(
    input clk, rst_n,
    input [DECODE_WIDTH-1:0] slave_sel,
    output reg [SLAVES-1:0] cs_n,
    // 公共SPI信号
    input sclk,
    input mosi,
    output miso,
    // 分时复用接口 - 使用标准Verilog数组
    input [7:0] tx_data_0,
    input [7:0] tx_data_1,
    input [7:0] tx_data_2,
    input [7:0] tx_data_3,
    output reg [7:0] rx_data_0,
    output reg [7:0] rx_data_1,
    output reg [7:0] rx_data_2,
    output reg [7:0] rx_data_3
);

reg [DECODE_WIDTH-1:0] active_slave;
reg [7:0] mux_reg;
wire [7:0] tx_data [0:SLAVES-1];
reg [7:0] rx_data [0:SLAVES-1];

// 映射数组输入
assign tx_data[0] = tx_data_0;
assign tx_data[1] = tx_data_1;
assign tx_data[2] = tx_data_2;
assign tx_data[3] = tx_data_3;

// 映射数组输出
always @(posedge clk) begin
    rx_data_0 <= rx_data[0];
    rx_data_1 <= rx_data[1];
    rx_data_2 <= rx_data[2];
    rx_data_3 <= rx_data[3];
end

// 片选译码器
always @(*) begin
    cs_n = {SLAVES{1'b1}};
    cs_n[active_slave] = 1'b0;
end

// 数据复用器
always @(posedge sclk) begin
    if (!cs_n[active_slave]) begin
        mux_reg <= tx_data[active_slave];
        rx_data[active_slave] <= {mux_reg[6:0], miso};
    end
end

// 仲裁逻辑
always @(posedge clk) begin
    if (cs_n == {SLAVES{1'b1}}) 
        active_slave <= slave_sel;
end

assign miso = mux_reg[7];
endmodule