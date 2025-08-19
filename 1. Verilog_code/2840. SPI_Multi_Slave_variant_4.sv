//SystemVerilog
//IEEE 1364-2005 Verilog
module SPI_Multi_Slave #(
    parameter SLAVES = 4,
    parameter DECODE_WIDTH = 2
)(
    input clk,
    input rst_n,
    input [DECODE_WIDTH-1:0] slave_sel,
    output [SLAVES-1:0] cs_n,
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

// 输入数据映射
wire [7:0] tx_data [0:SLAVES-1];
assign tx_data[0] = tx_data_0;
assign tx_data[1] = tx_data_1;
assign tx_data[2] = tx_data_2;
assign tx_data[3] = tx_data_3;

// 片选译码逻辑
wire [SLAVES-1:0] cs_n_decode;
assign cs_n_decode = (1 << slave_sel) ^ {SLAVES{1'b1}}; // 低电平有效

// 后向重定时——将cs_n寄存器提前到组合逻辑前
reg [SLAVES-1:0] cs_n_reg1, cs_n_reg2, cs_n_reg3;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cs_n_reg1 <= {SLAVES{1'b1}};
        cs_n_reg2 <= {SLAVES{1'b1}};
        cs_n_reg3 <= {SLAVES{1'b1}};
    end else begin
        cs_n_reg1 <= cs_n_decode;
        cs_n_reg2 <= cs_n_reg1;
        cs_n_reg3 <= cs_n_reg2;
    end
end
assign cs_n = cs_n_reg3;

// active_slave流水线后向重定时
reg [DECODE_WIDTH-1:0] active_slave_reg1, active_slave_reg2, active_slave_reg3;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        active_slave_reg1 <= {DECODE_WIDTH{1'b0}};
        active_slave_reg2 <= {DECODE_WIDTH{1'b0}};
        active_slave_reg3 <= {DECODE_WIDTH{1'b0}};
    end else begin
        active_slave_reg1 <= slave_sel;
        active_slave_reg2 <= active_slave_reg1;
        active_slave_reg3 <= active_slave_reg2;
    end
end

// SPI数据路径后向重定时
reg [7:0] mux_reg1, mux_reg2, mux_reg3;
reg miso_bit1, miso_bit2, miso_bit3;
reg [7:0] rx_shift1, rx_shift2, rx_shift3;

// 片选使能信号流水线
wire slave_active1, slave_active2, slave_active3;
assign slave_active1 = ~cs_n_reg1[active_slave_reg1];
assign slave_active2 = ~cs_n_reg2[active_slave_reg2];
assign slave_active3 = ~cs_n_reg3[active_slave_reg3];

// Stage1: 捕获tx_data
always @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        mux_reg1 <= 8'b0;
        miso_bit1 <= 1'b0;
        rx_shift1 <= 8'b0;
    end else if (slave_active1) begin
        mux_reg1 <= tx_data[active_slave_reg1];
        miso_bit1 <= mosi;
        rx_shift1 <= tx_data[active_slave_reg1];
    end
end

// Stage2: 移位操作
wire [7:0] rx_shift_next2;
assign rx_shift_next2 = {mux_reg1[6:0], mosi};

always @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        mux_reg2 <= 8'b0;
        miso_bit2 <= 1'b0;
        rx_shift2 <= 8'b0;
    end else begin
        mux_reg2 <= mux_reg1;
        miso_bit2 <= miso_bit1;
        rx_shift2 <= rx_shift_next2;
    end
end

// Stage3: 保持流水线
always @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        mux_reg3 <= 8'b0;
        miso_bit3 <= 1'b0;
        rx_shift3 <= 8'b0;
    end else begin
        mux_reg3 <= mux_reg2;
        miso_bit3 <= miso_bit2;
        rx_shift3 <= rx_shift2;
    end
end

// 接收数据寄存器后向重定时：提前采样到Stage2，Stage3只分发
reg [7:0] rx_data_array [0:SLAVES-1];
integer i;
always @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < SLAVES; i = i + 1)
            rx_data_array[i] <= 8'b0;
    end else if (slave_active2) begin
        rx_data_array[active_slave_reg2] <= rx_shift2;
    end
end

// Stage3仅作分发，保持独立路径
reg [7:0] rx_data_out_stage3 [0:SLAVES-1];
always @(posedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < SLAVES; i = i + 1)
            rx_data_out_stage3[i] <= 8'b0;
    end else begin
        for (i = 0; i < SLAVES; i = i + 1)
            rx_data_out_stage3[i] <= rx_data_array[i];
    end
end

// 映射数组输出到端口，保持同步
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_data_0 <= 8'b0;
        rx_data_1 <= 8'b0;
        rx_data_2 <= 8'b0;
        rx_data_3 <= 8'b0;
    end else begin
        rx_data_0 <= rx_data_out_stage3[0];
        rx_data_1 <= rx_data_out_stage3[1];
        rx_data_2 <= rx_data_out_stage3[2];
        rx_data_3 <= rx_data_out_stage3[3];
    end
end

// MISO输出后向重定时：提前到Stage2寄存
assign miso = mux_reg2[7];

endmodule