module UART_Sync_Basic #(
    parameter DATA_WIDTH = 8,
    parameter CLK_DIVISOR = 868  // 100MHz/115200
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [DATA_WIDTH-1:0] tx_data,
    input  wire tx_valid,
    output reg  tx_ready,
    output reg  txd,
    input  wire rxd,
    output reg  [DATA_WIDTH-1:0] rx_data,
    output reg  rx_valid
);
// 状态机采用参数定义
localparam IDLE  = 4'b0001;
localparam START = 4'b0010;
localparam DATA  = 4'b0100;
localparam STOP  = 4'b1000;

reg [3:0] state;
reg [$clog2(CLK_DIVISOR)-1:0] baud_cnt;
reg [3:0] bit_cnt;
// 发送端采用移位寄存器设计
reg [DATA_WIDTH+1:0] tx_shift;
// 接收端配置数字滤波器
reg [2:0] rxd_sync;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 复位状态初始化
        state <= IDLE;
        tx_ready <= 1'b1;
        txd <= 1'b1;
        baud_cnt <= 0;
        bit_cnt <= 0;
        rx_data <= 0;
        rx_valid <= 0;
        rxd_sync <= 3'b111;
        tx_shift <= 0;
    end else begin
        // 波特率生成器
        baud_cnt <= (baud_cnt == CLK_DIVISOR-1) ? 0 : baud_cnt + 1;
        
        // 简化状态机实现
        case(state)
            IDLE: begin
                if (tx_valid && tx_ready) begin
                    state <= START;
                    tx_ready <= 0;
                    tx_shift <= {1'b1, tx_data, 1'b0}; // 添加开始位和停止位
                end
            end
            START: begin
                if (baud_cnt == 0) begin
                    txd <= tx_shift[0];
                    tx_shift <= {1'b0, tx_shift[DATA_WIDTH+1:1]};
                    bit_cnt <= 0;
                    state <= DATA;
                end
            end
            DATA: begin
                if (baud_cnt == 0) begin
                    bit_cnt <= bit_cnt + 1;
                    txd <= tx_shift[0];
                    tx_shift <= {1'b0, tx_shift[DATA_WIDTH+1:1]};
                    if (bit_cnt == DATA_WIDTH) begin
                        state <= STOP;
                    end
                end
            end
            STOP: begin
                if (baud_cnt == 0) begin
                    txd <= 1'b1; // 停止位
                    state <= IDLE;
                    tx_ready <= 1'b1;
                end
            end
            default: state <= IDLE;
        endcase
    end
end
endmodule