//SystemVerilog
module UART_Sync_Basic #(
    parameter DATA_WIDTH = 8,
    parameter CLK_DIVISOR = 868  // 100MHz/115200
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [DATA_WIDTH-1:0] tx_data,
    input  wire tx_valid,
    output wire tx_ready,
    output wire txd,
    input  wire rxd,
    output wire [DATA_WIDTH-1:0] rx_data,
    output wire rx_valid
);
// 独冷(one-cold)编码状态机参数定义
localparam IDLE_STATE  = 4'b1110;
localparam START_STATE = 4'b1101;
localparam DATA_STATE  = 4'b1011;
localparam STOP_STATE  = 4'b0111;

reg [3:0] state_reg, state_buf1, state_buf2;
reg [$clog2(CLK_DIVISOR)-1:0] baud_cnt_reg, baud_cnt_buf1, baud_cnt_buf2;
reg [3:0] bit_cnt_reg, bit_cnt_buf;
reg [DATA_WIDTH+1:0] tx_shift_reg, tx_shift_buf1, tx_shift_buf2;
reg [2:0] rxd_sync_reg;
reg tx_ready_reg, tx_ready_buf;
reg txd_reg;
reg [DATA_WIDTH-1:0] rx_data_reg;
reg rx_valid_reg;

// 状态寄存器多级缓冲，降低扇出
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_reg  <= IDLE_STATE;
        state_buf1 <= IDLE_STATE;
        state_buf2 <= IDLE_STATE;
    end else begin
        state_buf1 <= state_reg;
        state_buf2 <= state_buf1;
    end
end

// 波特率计数器多级缓冲
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        baud_cnt_reg  <= 0;
        baud_cnt_buf1 <= 0;
        baud_cnt_buf2 <= 0;
    end else begin
        baud_cnt_buf1 <= baud_cnt_reg;
        baud_cnt_buf2 <= baud_cnt_buf1;
    end
end

// 发送移位寄存器多级缓冲
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_shift_reg  <= 0;
        tx_shift_buf1 <= 0;
        tx_shift_buf2 <= 0;
    end else begin
        tx_shift_buf1 <= tx_shift_reg;
        tx_shift_buf2 <= tx_shift_buf1;
    end
end

// 发送就绪信号缓冲
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_ready_reg <= 1'b1;
        tx_ready_buf <= 1'b1;
    end else begin
        tx_ready_buf <= tx_ready_reg;
    end
end

// bit_cnt单级缓冲
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bit_cnt_reg <= 0;
        bit_cnt_buf <= 0;
    end else begin
        bit_cnt_buf <= bit_cnt_reg;
    end
end

// 其余信号保持原有寄存器结构
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        txd_reg      <= 1'b1;
        rx_data_reg  <= 0;
        rx_valid_reg <= 0;
        rxd_sync_reg <= 3'b111;
    end
end

// 主时序逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_reg    <= IDLE_STATE;
        baud_cnt_reg <= 0;
        bit_cnt_reg  <= 0;
        tx_ready_reg <= 1'b1;
        txd_reg      <= 1'b1;
        tx_shift_reg <= 0;
        rx_data_reg  <= 0;
        rx_valid_reg <= 0;
        rxd_sync_reg <= 3'b111;
    end else begin
        // 波特率生成器
        baud_cnt_reg <= (baud_cnt_reg == CLK_DIVISOR-1) ? 0 : baud_cnt_reg + 1;

        // 状态机实现，所有高扇出信号均使用缓冲后的信号驱动
        case(state_buf2)
            IDLE_STATE: begin
                if (tx_valid && tx_ready_buf) begin
                    state_reg    <= START_STATE;
                    tx_ready_reg <= 1'b0;
                    tx_shift_reg <= {1'b1, tx_data, 1'b0}; // 添加开始位和停止位
                end
            end
            START_STATE: begin
                if (baud_cnt_buf2 == 0) begin
                    txd_reg      <= tx_shift_buf2[0];
                    tx_shift_reg <= {1'b0, tx_shift_buf2[DATA_WIDTH+1:1]};
                    bit_cnt_reg  <= 0;
                    state_reg    <= DATA_STATE;
                end
            end
            DATA_STATE: begin
                if (baud_cnt_buf2 == 0) begin
                    bit_cnt_reg  <= bit_cnt_buf + 1;
                    txd_reg      <= tx_shift_buf2[0];
                    tx_shift_reg <= {1'b0, tx_shift_buf2[DATA_WIDTH+1:1]};
                    if (bit_cnt_buf == DATA_WIDTH) begin
                        state_reg <= STOP_STATE;
                    end
                end
            end
            STOP_STATE: begin
                if (baud_cnt_buf2 == 0) begin
                    txd_reg      <= 1'b1; // 停止位
                    state_reg    <= IDLE_STATE;
                    tx_ready_reg <= 1'b1;
                end
            end
            default: state_reg <= IDLE_STATE;
        endcase
    end
end

// 输出信号赋值
assign txd      = txd_reg;
assign tx_ready = tx_ready_buf;
assign rx_data  = rx_data_reg;
assign rx_valid = rx_valid_reg;

endmodule