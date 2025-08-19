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

// 状态机参数定义
localparam IDLE  = 4'b0001;
localparam START = 4'b0010;
localparam DATA  = 4'b0100;
localparam STOP  = 4'b1000;

// Stage 1: 输入采集与启动判定
reg  [3:0] state_stage1;
reg        tx_ready_stage1;
reg  [DATA_WIDTH-1:0] tx_data_stage1;
reg        tx_valid_stage1;
reg        flush_stage1;
reg  [DATA_WIDTH+1:0] tx_shift_stage1;
reg  [$clog2(CLK_DIVISOR)-1:0] baud_cnt_stage1;
reg  [3:0] bit_cnt_stage1;
reg        valid_stage1;

// Stage 2: 状态转移与移位
reg  [3:0] state_stage2;
reg        tx_ready_stage2;
reg  [DATA_WIDTH+1:0] tx_shift_stage2;
reg  [$clog2(CLK_DIVISOR)-1:0] baud_cnt_stage2;
reg  [3:0] bit_cnt_stage2;
reg        txd_stage2;
reg        valid_stage2;
reg        flush_stage2;

// Stage 3: 输出寄存
wire       tx_ready_stage3;
wire       txd_stage3;
wire       valid_stage3;

// 控制信号
assign tx_ready = tx_ready_stage2;
assign txd      = txd_stage2;

// 无更改的接收端接口（占位）
assign rx_data  = {DATA_WIDTH{1'b0}};
assign rx_valid = 1'b0;

// Stage 1: 输入采集与启动判定
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_stage1      <= IDLE;
        tx_ready_stage1   <= 1'b1;
        tx_data_stage1    <= {DATA_WIDTH{1'b0}};
        tx_valid_stage1   <= 1'b0;
        tx_shift_stage1   <= {DATA_WIDTH+2{1'b0}};
        baud_cnt_stage1   <= {($clog2(CLK_DIVISOR)){1'b0}};
        bit_cnt_stage1    <= 4'd0;
        valid_stage1      <= 1'b0;
        flush_stage1      <= 1'b0;
    end else begin
        // 波特率生成器
        if (baud_cnt_stage1 == CLK_DIVISOR-1)
            baud_cnt_stage1 <= {($clog2(CLK_DIVISOR)){1'b0}};
        else
            baud_cnt_stage1 <= baud_cnt_stage1 + 1'b1;

        // 状态与输入采集
        tx_data_stage1  <= tx_data;
        tx_valid_stage1 <= tx_valid;
        flush_stage1    <= 1'b0;

        case(state_stage1)
            IDLE: begin
                tx_ready_stage1 <= 1'b1;
                if (tx_valid && tx_ready_stage1) begin
                    state_stage1    <= START;
                    tx_ready_stage1 <= 1'b0;
                    tx_shift_stage1 <= {1'b1, tx_data, 1'b0}; // 停止位+数据+起始位
                    valid_stage1    <= 1'b1;
                end else begin
                    valid_stage1    <= 1'b0;
                end
                bit_cnt_stage1  <= 4'd0;
            end
            START: begin
                valid_stage1 <= 1'b1;
                if (baud_cnt_stage1 == 0)
                    state_stage1 <= DATA;
            end
            DATA: begin
                valid_stage1 <= 1'b1;
                if (baud_cnt_stage1 == 0) begin
                    if (bit_cnt_stage1 == DATA_WIDTH) begin
                        state_stage1 <= STOP;
                    end
                    bit_cnt_stage1 <= bit_cnt_stage1 + 1'b1;
                end
            end
            STOP: begin
                valid_stage1 <= 1'b1;
                if (baud_cnt_stage1 == 0) begin
                    state_stage1    <= IDLE;
                    tx_ready_stage1 <= 1'b1;
                    flush_stage1    <= 1'b1;
                end
            end
            default: begin
                state_stage1    <= IDLE;
                tx_ready_stage1 <= 1'b1;
                valid_stage1    <= 1'b0;
                flush_stage1    <= 1'b0;
            end
        endcase
    end
end

// Stage 2: 状态转移与移位 + 后向重定时寄存器
reg        tx_ready_stage2_reg;
reg        txd_stage2_reg;
reg        valid_stage2_reg;
reg        flush_stage2_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_stage2      <= IDLE;
        tx_ready_stage2   <= 1'b1;
        tx_shift_stage2   <= {DATA_WIDTH+2{1'b0}};
        baud_cnt_stage2   <= {($clog2(CLK_DIVISOR)){1'b0}};
        bit_cnt_stage2    <= 4'd0;
        txd_stage2        <= 1'b1;
        valid_stage2      <= 1'b0;
        flush_stage2      <= 1'b0;
        tx_ready_stage2_reg <= 1'b1;
        txd_stage2_reg      <= 1'b1;
        valid_stage2_reg    <= 1'b0;
        flush_stage2_reg    <= 1'b0;
    end else begin
        // 刷新逻辑
        if (flush_stage1) begin
            state_stage2      <= IDLE;
            tx_ready_stage2   <= 1'b1;
            tx_shift_stage2   <= {DATA_WIDTH+2{1'b0}};
            baud_cnt_stage2   <= {($clog2(CLK_DIVISOR)){1'b0}};
            bit_cnt_stage2    <= 4'd0;
            txd_stage2        <= 1'b1;
            valid_stage2      <= 1'b0;
            flush_stage2      <= 1'b1;
            tx_ready_stage2_reg <= 1'b1;
            txd_stage2_reg      <= 1'b1;
            valid_stage2_reg    <= 1'b0;
            flush_stage2_reg    <= 1'b1;
        end else if (valid_stage1) begin
            state_stage2      <= state_stage1;
            tx_ready_stage2   <= tx_ready_stage1;
            tx_shift_stage2   <= tx_shift_stage1;
            baud_cnt_stage2   <= baud_cnt_stage1;
            bit_cnt_stage2    <= bit_cnt_stage1;
            flush_stage2      <= 1'b0;
            valid_stage2      <= 1'b1;
            // 发送移位与txd更新
            case(state_stage1)
                START: begin
                    if (baud_cnt_stage1 == 0) begin
                        txd_stage2      <= tx_shift_stage1[0];
                        tx_shift_stage2 <= {1'b0, tx_shift_stage1[DATA_WIDTH+1:1]};
                    end else begin
                        txd_stage2      <= txd_stage2;
                        tx_shift_stage2 <= tx_shift_stage2;
                    end
                end
                DATA: begin
                    if (baud_cnt_stage1 == 0) begin
                        txd_stage2      <= tx_shift_stage1[0];
                        tx_shift_stage2 <= {1'b0, tx_shift_stage1[DATA_WIDTH+1:1]};
                    end else begin
                        txd_stage2      <= txd_stage2;
                        tx_shift_stage2 <= tx_shift_stage2;
                    end
                end
                STOP: begin
                    if (baud_cnt_stage1 == 0)
                        txd_stage2 <= 1'b1;
                    else
                        txd_stage2 <= txd_stage2;
                end
                default: begin
                    txd_stage2 <= 1'b1;
                end
            endcase
            // 后向重定时寄存器：将输出寄存器拉入Stage2
            tx_ready_stage2_reg <= tx_ready_stage2;
            txd_stage2_reg      <= txd_stage2;
            valid_stage2_reg    <= 1'b1;
            flush_stage2_reg    <= flush_stage2;
        end else begin
            valid_stage2      <= 1'b0;
            flush_stage2      <= 1'b0;
            tx_ready_stage2_reg <= tx_ready_stage2_reg;
            txd_stage2_reg      <= txd_stage2_reg;
            valid_stage2_reg    <= 1'b0;
            flush_stage2_reg    <= 1'b0;
        end
    end
end

// Stage 3: 输出寄存(已后拉至Stage2, 仅组合赋值)
assign tx_ready_stage3 = tx_ready_stage2_reg;
assign txd_stage3      = txd_stage2_reg;
assign valid_stage3    = valid_stage2_reg;

endmodule