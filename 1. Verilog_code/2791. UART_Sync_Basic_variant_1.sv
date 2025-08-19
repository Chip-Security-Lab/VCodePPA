//SystemVerilog
`timescale 1ns/1ps

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

    // 主流水线结构化信号定义
    // Stage 0: 寄存器同步输入
    reg [DATA_WIDTH-1:0] tx_data_pipe;
    reg                  tx_valid_pipe;
    reg                  rxd_pipe;

    // Stage 1: 起始和停止位、数据拼接及状态同步
    reg [DATA_WIDTH+1:0] tx_shift_stage1;
    reg                  tx_ready_stage1;
    reg [3:0]            state_stage1;
    reg [$clog2(CLK_DIVISOR)-1:0] baud_cnt_stage1;
    reg [3:0]            bit_cnt_stage1;
    reg                  txd_stage1;

    // Stage 2: 波特率计数与数据移位
    reg [DATA_WIDTH+1:0] tx_shift_stage2;
    reg                  tx_ready_stage2;
    reg [3:0]            state_stage2;
    reg [$clog2(CLK_DIVISOR)-1:0] baud_cnt_stage2;
    reg [3:0]            bit_cnt_stage2;
    reg                  txd_stage2;

    // Stage 3: 输出寄存器
    reg                  tx_ready_out;
    reg                  txd_out;

    // RX同步与数据暂存
    reg [2:0]            rxd_sync;
    reg [DATA_WIDTH-1:0] rx_data_reg;
    reg                  rx_valid_reg;

    // 状态机状态编码
    localparam UART_IDLE  = 4'b0001;
    localparam UART_START = 4'b0010;
    localparam UART_DATA  = 4'b0100;
    localparam UART_STOP  = 4'b1000;

    // TX输入同步流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_data_pipe  <= {DATA_WIDTH{1'b0}};
            tx_valid_pipe <= 1'b0;
            rxd_pipe      <= 1'b1;
        end else begin
            tx_data_pipe  <= tx_data;
            tx_valid_pipe <= tx_valid;
            rxd_pipe      <= rxd;
        end
    end

    // Stage 1: 状态与起始准备
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1      <= UART_IDLE;
            baud_cnt_stage1   <= {($clog2(CLK_DIVISOR)){1'b0}};
            bit_cnt_stage1    <= 4'b0000;
            tx_shift_stage1   <= {DATA_WIDTH+2{1'b0}};
            tx_ready_stage1   <= 1'b1;
            txd_stage1        <= 1'b1;
        end else begin
            state_stage1      <= state_stage2;
            baud_cnt_stage1   <= baud_cnt_stage2;
            bit_cnt_stage1    <= bit_cnt_stage2;
            tx_shift_stage1   <= tx_shift_stage2;
            tx_ready_stage1   <= tx_ready_stage2;
            txd_stage1        <= txd_stage2;
        end
    end

    // Stage 2: 状态机主逻辑及波特率计数
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2      <= UART_IDLE;
            baud_cnt_stage2   <= {($clog2(CLK_DIVISOR)){1'b0}};
            bit_cnt_stage2    <= 4'b0000;
            tx_shift_stage2   <= {DATA_WIDTH+2{1'b0}};
            tx_ready_stage2   <= 1'b1;
            txd_stage2        <= 1'b1;
        end else begin
            state_stage2    <= state_stage2;
            baud_cnt_stage2 <= baud_cnt_stage2;
            bit_cnt_stage2  <= bit_cnt_stage2;
            tx_shift_stage2 <= tx_shift_stage2;
            tx_ready_stage2 <= tx_ready_stage2;
            txd_stage2      <= txd_stage2;

            // 波特率计数器
            if (baud_cnt_stage1 == CLK_DIVISOR-1)
                baud_cnt_stage2 <= {($clog2(CLK_DIVISOR)){1'b0}};
            else
                baud_cnt_stage2 <= baud_cnt_stage1 + 1'b1;

            case (state_stage1)
                UART_IDLE: begin
                    if (tx_valid_pipe && tx_ready_stage1) begin
                        state_stage2    <= UART_START;
                        tx_ready_stage2 <= 1'b0;
                        tx_shift_stage2 <= {1'b1, tx_data_pipe, 1'b0}; // stop+data+start
                        bit_cnt_stage2  <= 4'b0000;
                        txd_stage2      <= 1'b1;
                    end else begin
                        state_stage2    <= UART_IDLE;
                        tx_ready_stage2 <= 1'b1;
                        txd_stage2      <= 1'b1;
                        tx_shift_stage2 <= tx_shift_stage1;
                        bit_cnt_stage2  <= bit_cnt_stage1;
                    end
                end
                UART_START: begin
                    if (baud_cnt_stage1 == 0) begin
                        txd_stage2      <= tx_shift_stage1[0];
                        tx_shift_stage2 <= {1'b0, tx_shift_stage1[DATA_WIDTH+1:1]};
                        state_stage2    <= UART_DATA;
                        bit_cnt_stage2  <= 4'b0000;
                    end else begin
                        txd_stage2      <= txd_stage1;
                        tx_shift_stage2 <= tx_shift_stage1;
                        state_stage2    <= UART_START;
                        bit_cnt_stage2  <= bit_cnt_stage1;
                    end
                end
                UART_DATA: begin
                    if (baud_cnt_stage1 == 0) begin
                        txd_stage2      <= tx_shift_stage1[0];
                        tx_shift_stage2 <= {1'b0, tx_shift_stage1[DATA_WIDTH+1:1]};
                        bit_cnt_stage2  <= bit_cnt_stage1 + 1'b1;
                        if (bit_cnt_stage1 == DATA_WIDTH)
                            state_stage2 <= UART_STOP;
                        else
                            state_stage2 <= UART_DATA;
                    end else begin
                        txd_stage2      <= txd_stage1;
                        tx_shift_stage2 <= tx_shift_stage1;
                        bit_cnt_stage2  <= bit_cnt_stage1;
                        state_stage2    <= UART_DATA;
                    end
                end
                UART_STOP: begin
                    if (baud_cnt_stage1 == 0) begin
                        txd_stage2      <= 1'b1;
                        state_stage2    <= UART_IDLE;
                        tx_ready_stage2 <= 1'b1;
                        bit_cnt_stage2  <= 4'b0000;
                        tx_shift_stage2 <= tx_shift_stage1;
                    end else begin
                        txd_stage2      <= txd_stage1;
                        state_stage2    <= UART_STOP;
                        tx_ready_stage2 <= tx_ready_stage1;
                        bit_cnt_stage2  <= bit_cnt_stage1;
                        tx_shift_stage2 <= tx_shift_stage1;
                    end
                end
                default: begin
                    state_stage2      <= UART_IDLE;
                    tx_ready_stage2   <= 1'b1;
                    txd_stage2        <= 1'b1;
                    tx_shift_stage2   <= {DATA_WIDTH+2{1'b0}};
                    bit_cnt_stage2    <= 4'b0000;
                end
            endcase
        end
    end

    // Stage 3: 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_ready_out <= 1'b1;
            txd_out      <= 1'b1;
        end else begin
            tx_ready_out <= tx_ready_stage2;
            txd_out      <= txd_stage2;
        end
    end

    // RX同步与数据暂存（保留原始结构，未做完整流水线）
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rxd_sync     <= 3'b111;
            rx_data_reg  <= {DATA_WIDTH{1'b0}};
            rx_valid_reg <= 1'b0;
        end else begin
            rxd_sync     <= {rxd_sync[1:0], rxd_pipe};
            rx_data_reg  <= rx_data_reg; // 原始代码未实现接收逻辑，这里保持
            rx_valid_reg <= 1'b0;
        end
    end

    // 输出信号
    assign tx_ready = tx_ready_out;
    assign txd      = txd_out;
    assign rx_data  = rx_data_reg;
    assign rx_valid = rx_valid_reg;

endmodule