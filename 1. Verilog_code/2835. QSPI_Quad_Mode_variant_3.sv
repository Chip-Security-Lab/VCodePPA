//SystemVerilog
//IEEE 1364-2005 Verilog
module QSPI_Quad_Mode #(
    parameter DDR_EN = 0
)(
    inout [3:0] io,
    input wire sck,
    input wire ddr_clk,
    output reg [31:0] rx_fifo,
    input [1:0] mode, // 00:SPI, 01:dual, 10:quad
    input wire rst_n,
    input wire start,
    output wire ready
);

//////////////////////////////
// 流水线级信号定义
//////////////////////////////

// Stage 1: 组合逻辑，输入采样和模式解析移入Stage 2
wire [1:0] mode_stage1_w;
wire [3:0] io_stage1_w;
wire sck_stage1_w;
wire start_stage1_w;
wire rst_n_stage1_w;
wire valid_stage1_w;

// Stage 2: IO方向、数据采集
reg [1:0] mode_stage2;
reg [3:0] io_dir_stage2;
reg [3:0] rx_data_stage2;
reg valid_stage2;
reg rst_n_stage2;
reg start_stage2;
reg sck_stage2;

// Stage 3: 数据拼接与FIFO写入
reg [31:0] rx_fifo_stage3;
reg [3:0] rx_data_stage3;
reg valid_stage3;
reg rst_n_stage3;
reg [1:0] mode_stage3;
reg start_stage3;
reg sck_stage3;

// Valid信号链
// 移动valid_stage1为组合逻辑信号
// reg valid_stage1;

// Ready信号
assign ready = ~valid_stage3;

// IO方向和数据寄存器
reg [3:0] tx_data;

// IO三态控制
assign io[0] = (io_dir_stage2[0]) ? tx_data[0] : 1'bz;
assign io[1] = (io_dir_stage2[1]) ? tx_data[1] : 1'bz;
assign io[2] = (io_dir_stage2[2]) ? tx_data[2] : 1'bz;
assign io[3] = (io_dir_stage2[3]) ? tx_data[3] : 1'bz;

// 前向重定时：将输入采样寄存器移到Stage 2组合逻辑后
assign mode_stage1_w   = mode;
assign io_stage1_w     = io;
assign sck_stage1_w    = sck;
assign start_stage1_w  = start;
assign rst_n_stage1_w  = rst_n;
assign valid_stage1_w  = start;

//////////////////////////////
// Stage 2: IO方向、数据采集（含输入采样）
//////////////////////////////
always @(posedge sck or negedge rst_n) begin
    if (!rst_n) begin
        mode_stage2      <= 2'b00;
        io_dir_stage2    <= 4'b0000;
        rx_data_stage2   <= 4'b0000;
        valid_stage2     <= 1'b0;
        rst_n_stage2     <= 1'b0;
        start_stage2     <= 1'b0;
        sck_stage2       <= 1'b0;
    end else begin
        mode_stage2      <= mode_stage1_w;
        start_stage2     <= start_stage1_w;
        sck_stage2       <= sck_stage1_w;
        rst_n_stage2     <= rst_n_stage1_w;
        valid_stage2     <= valid_stage1_w;
        case (mode_stage1_w)
            2'b00: begin
                // SPI模式
                io_dir_stage2  <= 4'b0001;
                rx_data_stage2 <= {3'b000, io_stage1_w[1]}; // 只取MISO
            end
            2'b01: begin
                // 双线模式
                io_dir_stage2  <= 4'b0011;
                rx_data_stage2 <= {2'b00, io_stage1_w[1:0]};
            end
            2'b10: begin
                // 四线模式
                io_dir_stage2  <= 4'b1111;
                rx_data_stage2 <= io_stage1_w;
            end
            default: begin
                io_dir_stage2  <= 4'b0000;
                rx_data_stage2 <= 4'b0000;
            end
        endcase
    end
end

//////////////////////////////
// Stage 3: 数据拼接与FIFO写入
//////////////////////////////
always @(posedge sck or negedge rst_n_stage2) begin
    if (!rst_n_stage2) begin
        rx_fifo_stage3   <= 32'b0;
        rx_data_stage3   <= 4'b0000;
        valid_stage3     <= 1'b0;
        rst_n_stage3     <= 1'b0;
        mode_stage3      <= 2'b00;
        start_stage3     <= 1'b0;
        sck_stage3       <= 1'b0;
    end else begin
        rst_n_stage3     <= rst_n_stage2;
        valid_stage3     <= valid_stage2;
        rx_data_stage3   <= rx_data_stage2;
        mode_stage3      <= mode_stage2;
        start_stage3     <= start_stage2;
        sck_stage3       <= sck_stage2;
        if (valid_stage2) begin
            if (mode_stage2 == 2'b10) begin
                rx_fifo_stage3 <= {rx_fifo_stage3[27:0], rx_data_stage2};
            end else begin
                rx_fifo_stage3 <= rx_fifo_stage3;
            end
        end
    end
end

//////////////////////////////
// 输出寄存器
//////////////////////////////
always @(posedge sck or negedge rst_n_stage3) begin
    if (!rst_n_stage3) begin
        rx_fifo <= 32'b0;
    end else begin
        if (valid_stage3 && (mode_stage3 == 2'b10)) begin
            rx_fifo <= rx_fifo_stage3;
        end
    end
end

endmodule