//SystemVerilog
module UART_MultiChannel #(
    parameter CHANNELS = 4,
    parameter CHAN_WIDTH = 2
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [CHAN_WIDTH-1:0] sel_chan,
    output reg  [CHANNELS-1:0]  txd_bus,
    input  wire [CHANNELS-1:0]  rxd_bus,
    input  wire [7:0]           tx_data,
    output reg  [7:0]           rx_data,
    input  wire                 cycle_start
);

// 通道循环计数器
reg [CHAN_WIDTH-1:0] time_slot;
reg [CHAN_WIDTH-1:0] time_slot_buf1;
reg [CHAN_WIDTH-1:0] time_slot_buf2;

// 通道激活寄存器
reg [CHANNELS-1:0] chan_enable;
reg [CHANNELS-1:0] chan_enable_buf1;
reg [CHANNELS-1:0] chan_enable_buf2;

// 动态波特率配置存储
reg [15:0] baud_table [0:CHANNELS-1];

// 通道缓存和缓冲（多级缓冲扇出）
reg [7:0] mux_tx_data       [0:CHANNELS-1];
reg [7:0] mux_tx_data_buf1  [0:CHANNELS-1];
reg [7:0] mux_tx_data_buf2  [0:CHANNELS-1];

reg [7:0] mux_rx_data       [0:CHANNELS-1];
reg [7:0] mux_rx_data_buf1  [0:CHANNELS-1];
reg [7:0] mux_rx_data_buf2  [0:CHANNELS-1];

// ----------- 高扇出 CHANNELS 缓冲结构 -----------
reg [31:0] channels_buf1;
reg [31:0] channels_buf2;

// ----------- 高扇出 sel_chan 缓冲 -----------
reg [CHAN_WIDTH-1:0] sel_chan_buf1;
reg [CHAN_WIDTH-1:0] sel_chan_buf2;

// ----------- 选择通道缓冲 -----------
reg [7:0] tx_shift_reg;
reg [15:0] current_baud_reg;

// 初始化和复位逻辑
integer i;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        time_slot <= {CHAN_WIDTH{1'b0}};
        time_slot_buf1 <= {CHAN_WIDTH{1'b0}};
        time_slot_buf2 <= {CHAN_WIDTH{1'b0}};
        chan_enable <= {CHANNELS{1'b0}};
        chan_enable_buf1 <= {CHANNELS{1'b0}};
        chan_enable_buf2 <= {CHANNELS{1'b0}};
        txd_bus <= {CHANNELS{1'b1}};
        rx_data <= 8'd0;
        tx_shift_reg <= 8'd0;
        current_baud_reg <= 16'd0;
        sel_chan_buf1 <= {CHAN_WIDTH{1'b0}};
        sel_chan_buf2 <= {CHAN_WIDTH{1'b0}};
        channels_buf1 <= 32'd0;
        channels_buf2 <= 32'd0;
        for (i = 0; i < CHANNELS; i = i + 1) begin
            mux_tx_data[i]      <= 8'd0;
            mux_tx_data_buf1[i] <= 8'd0;
            mux_tx_data_buf2[i] <= 8'd0;
            mux_rx_data[i]      <= 8'd0;
            mux_rx_data_buf1[i] <= 8'd0;
            mux_rx_data_buf2[i] <= 8'd0;
            baud_table[i]       <= 16'd0;
        end
    end else begin
        // 高扇出 CHANNELS 缓冲
        channels_buf1 <= { {(32-CHANNELS){1'b0}}, {CHANNELS{1'b1}} };
        channels_buf2 <= channels_buf1;

        // 高扇出 time_slot 缓冲
        time_slot_buf1 <= time_slot;
        time_slot_buf2 <= time_slot_buf1;

        // 高扇出 chan_enable 缓冲
        chan_enable_buf1 <= chan_enable;
        chan_enable_buf2 <= chan_enable_buf1;

        // 高扇出 sel_chan 缓冲
        sel_chan_buf1 <= sel_chan;
        sel_chan_buf2 <= sel_chan_buf1;

        // 保存传入的发送数据到对应通道
        mux_tx_data[sel_chan_buf2] <= tx_data;

        // 高扇出 mux_tx_data 缓冲
        for (i = 0; i < CHANNELS; i = i + 1) begin
            mux_tx_data_buf1[i] <= mux_tx_data[i];
            mux_tx_data_buf2[i] <= mux_tx_data_buf1[i];
        end

        // 高扇出 mux_rx_data 缓冲
        for (i = 0; i < CHANNELS; i = i + 1) begin
            mux_rx_data_buf1[i] <= mux_rx_data[i];
            mux_rx_data_buf2[i] <= mux_rx_data_buf1[i];
        end

        // 输出当前选择通道的接收数据(用缓冲)
        rx_data <= mux_rx_data_buf2[sel_chan_buf2];

        // 发送时分复用逻辑(用缓冲)
        if (cycle_start) begin
            if (time_slot_buf2 == CHANNELS-1)
                time_slot <= {CHAN_WIDTH{1'b0}};
            else
                time_slot <= time_slot_buf2 + 1'b1;
            txd_bus <= channels_buf2[CHANNELS-1:0];
            txd_bus[time_slot_buf2] <= tx_shift_reg[0];
        end

        // 接收数据处理(用缓冲)
        for (i = 0; i < CHANNELS; i = i + 1) begin
            if (rxd_bus[i] == 1'b0) begin
                mux_rx_data[i] <= {mux_rx_data[i][6:0], rxd_bus[i]};
            end
        end
    end
end

// 通道配置加载逻辑，全部缓冲
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_shift_reg <= 8'd0;
        current_baud_reg <= 16'd0;
    end else begin
        current_baud_reg <= baud_table[sel_chan_buf2];
        tx_shift_reg <= mux_tx_data_buf2[sel_chan_buf2];
    end
end

endmodule