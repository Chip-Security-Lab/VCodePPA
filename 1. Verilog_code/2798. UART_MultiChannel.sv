module UART_MultiChannel #(
    parameter CHANNELS = 4,
    parameter CHAN_WIDTH = 2  // 用确定的宽度替代$clog2表达式
)(
    input  wire clk,
    input  wire rst_n,         // 添加复位信号
    input  wire [CHAN_WIDTH-1:0] sel_chan,  // 通道选择
    output reg  [CHANNELS-1:0]  txd_bus,    // 通道物理总线
    input  wire [CHANNELS-1:0]  rxd_bus,
    // 时分复用接口
    input  wire [7:0]           tx_data,    // 修改为单个数据输入
    output reg  [7:0]           rx_data,    // 修改为单个数据输出
    input  wire                 cycle_start  // 时隙同步
);
// 通道循环计数器
reg [CHAN_WIDTH-1:0] time_slot;
// 通道激活寄存器
reg [CHANNELS-1:0] chan_enable;

// 动态波特率配置存储
reg [15:0] baud_table [0:CHANNELS-1];
reg [7:0] tx_shift;
reg [15:0] current_baud;

// 通道缓存
reg [7:0] mux_tx_data [0:CHANNELS-1];
reg [7:0] mux_rx_data [0:CHANNELS-1];

// 初始化和复位逻辑
integer i;
// 不使用initial块，改用同步复位

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        time_slot <= 0;
        chan_enable <= 0;
        txd_bus <= {CHANNELS{1'b1}};
        rx_data <= 0;
        tx_shift <= 0; // 添加tx_shift初始化
        current_baud <= 0; // 添加current_baud初始化
        
        for (i = 0; i < CHANNELS; i = i + 1) begin
            mux_tx_data[i] <= 8'd0;
            mux_rx_data[i] <= 8'd0;
            baud_table[i] <= 16'd0;
        end
    end
    else begin
        // 保存传入的发送数据到对应通道
        mux_tx_data[sel_chan] <= tx_data;
        
        // 输出当前选择通道的接收数据
        rx_data <= mux_rx_data[sel_chan];
        
        // 发送时分复用逻辑
        if (cycle_start) begin
            time_slot <= (time_slot == CHANNELS-1) ? 0 : time_slot + 1;
            txd_bus <= {CHANNELS{1'b1}};  // 默认置高
            txd_bus[time_slot] <= tx_shift[0];  // 激活当前时隙
        end
        
        // 接收数据处理
        for (i = 0; i < CHANNELS; i = i + 1) begin
            if (rxd_bus[i] == 1'b0) begin  // 简化处理，检测开始位
                mux_rx_data[i] <= {mux_rx_data[i][6:0], rxd_bus[i]};
            end
        end
    end
end

// 通道配置加载逻辑
always @(*) begin
    current_baud = baud_table[sel_chan];
    tx_shift = mux_tx_data[sel_chan];
end
endmodule