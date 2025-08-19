//SystemVerilog
// 顶层模块：UART_DualClock_Pipelined
module UART_DualClock_Pipelined #(
    parameter DATA_WIDTH = 9,
    parameter FIFO_DEPTH = 16,
    parameter SYNC_STAGES = 3
)(
    input  wire tx_clk,
    input  wire rx_clk,
    input  wire sys_rst,
    // 系统接口
    input  wire [DATA_WIDTH-1:0] data_in,
    input  wire wr_en,
    output wire full,
    // 物理接口
    output wire txd,
    input  wire rxd,
    // 状态指示
    output wire frame_error,
    output wire parity_error
);

    // Pipeline Stage 1: 数据输入与奇偶校验生成
    wire [DATA_WIDTH-2:0] input_data_stage1;
    wire                  parity_bit_stage1;
    wire [DATA_WIDTH-1:0] fifo_din_stage1;
    assign input_data_stage1 = data_in[DATA_WIDTH-2:0];

    ParityGen #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_parity_gen (
        .data_in(input_data_stage1),
        .parity_bit(parity_bit_stage1)
    );
    assign fifo_din_stage1 = {parity_bit_stage1, data_in};

    // Pipeline Stage 2: FIFO写入
    wire [$clog2(FIFO_DEPTH):0] wr_ptr_stage2;
    wire [$clog2(FIFO_DEPTH):0] rd_ptr_stage2;
    wire [DATA_WIDTH-1:0] fifo_dout_stage2;
    wire fifo_wr_en_stage2;
    wire fifo_rd_en_stage2;
    wire fifo_empty_stage2;
    wire fifo_full_stage2;
    wire [$clog2(FIFO_DEPTH):0] wr_ptr_gray_stage2;
    wire [$clog2(FIFO_DEPTH):0] rd_ptr_gray_stage2;

    assign fifo_wr_en_stage2 = wr_en;

    UART_FIFO_Pipelined #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) u_uart_fifo (
        .tx_clk(tx_clk),
        .rx_clk(rx_clk),
        .sys_rst(sys_rst),
        .data_in(fifo_din_stage1),
        .wr_en(fifo_wr_en_stage2),
        .rd_en(fifo_rd_en_stage2),
        .data_out(fifo_dout_stage2),
        .wr_ptr(wr_ptr_stage2),
        .rd_ptr(rd_ptr_stage2),
        .wr_ptr_gray(wr_ptr_gray_stage2),
        .rd_ptr_gray(rd_ptr_gray_stage2),
        .full(fifo_full_stage2),
        .empty(fifo_empty_stage2)
    );
    assign full = fifo_full_stage2;

    // Pipeline Stage 3: 指针Gray码同步
    wire [$clog2(FIFO_DEPTH):0] wr_ptr_gray_sync_stage3;
    wire [$clog2(FIFO_DEPTH):0] rd_ptr_gray_sync_stage3;

    GraySync #(
        .WIDTH($clog2(FIFO_DEPTH)+1),
        .STAGES(SYNC_STAGES)
    ) u_wr_ptr_gray_sync (
        .clk(rx_clk),
        .rst(sys_rst),
        .d_in(wr_ptr_gray_stage2),
        .d_out(wr_ptr_gray_sync_stage3)
    );

    GraySync #(
        .WIDTH($clog2(FIFO_DEPTH)+1),
        .STAGES(SYNC_STAGES)
    ) u_rd_ptr_gray_sync (
        .clk(tx_clk),
        .rst(sys_rst),
        .d_in(rd_ptr_gray_stage2),
        .d_out(rd_ptr_gray_sync_stage3)
    );

    // Pipeline Stage 4: UART发送
    wire txd_stage4;
    wire fifo_rd_en_stage4;

    UART_Tx_Pipelined #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_uart_tx (
        .clk(tx_clk),
        .rst(sys_rst),
        .fifo_empty(fifo_empty_stage2),
        .fifo_data(fifo_dout_stage2),
        .fifo_rd_en(fifo_rd_en_stage4),
        .txd(txd_stage4)
    );
    assign fifo_rd_en_stage2 = fifo_rd_en_stage4;
    assign txd = txd_stage4;

    // Pipeline Stage 5: UART接收与错误检测
    wire frame_error_stage5;
    wire parity_error_stage5;

    UART_Rx_Pipelined #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_uart_rx (
        .clk(rx_clk),
        .rst(sys_rst),
        .rxd(rxd),
        .frame_error(frame_error_stage5),
        .parity_error(parity_error_stage5)
    );
    assign frame_error = frame_error_stage5;
    assign parity_error = parity_error_stage5;

endmodule

// FIFO模块：双时钟，带Gray码指针同步，增加流水线寄存器切分逻辑
module UART_FIFO_Pipelined #(
    parameter DATA_WIDTH = 9,
    parameter FIFO_DEPTH = 16
)(
    input  wire tx_clk,
    input  wire rx_clk,
    input  wire sys_rst,
    input  wire [DATA_WIDTH-1:0] data_in,
    input  wire wr_en,
    input  wire rd_en,
    output reg  [DATA_WIDTH-1:0] data_out,
    output reg  [$clog2(FIFO_DEPTH):0] wr_ptr,
    output reg  [$clog2(FIFO_DEPTH):0] rd_ptr,
    output wire [$clog2(FIFO_DEPTH):0] wr_ptr_gray,
    output wire [$clog2(FIFO_DEPTH):0] rd_ptr_gray,
    output wire full,
    output wire empty
);

    reg [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];

    // Pipeline register for write data (切分写入路径)
    reg [DATA_WIDTH-1:0] write_data_pipe;
    reg                  write_data_valid_pipe;

    // Pipeline register for read data (切分读出路径)
    reg [DATA_WIDTH-1:0] read_data_pipe;
    reg                  read_data_valid_pipe;

    // Gray码转换函数
    function [$clog2(FIFO_DEPTH):0] bin2gray;
        input [$clog2(FIFO_DEPTH):0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    assign wr_ptr_gray = bin2gray(wr_ptr);
    assign rd_ptr_gray = bin2gray(rd_ptr);

    // 写指针逻辑 (TX时钟域) - Pipeline
    always @(posedge tx_clk or posedge sys_rst) begin
        if (sys_rst) begin
            wr_ptr <= 0;
            write_data_pipe <= 0;
            write_data_valid_pipe <= 0;
        end else begin
            // Pipeline stage 1: latch input
            write_data_pipe <= data_in;
            write_data_valid_pipe <= wr_en && !full;
            // Pipeline stage 2: commit to memory
            if (write_data_valid_pipe) begin
                fifo_mem[wr_ptr[$clog2(FIFO_DEPTH)-1:0]] <= write_data_pipe;
                wr_ptr <= wr_ptr + 1;
            end
        end
    end

    // 读指针逻辑 (RX时钟域) - Pipeline
    always @(posedge rx_clk or posedge sys_rst) begin
        if (sys_rst) begin
            rd_ptr <= 0;
            data_out <= 0;
            read_data_pipe <= 0;
            read_data_valid_pipe <= 0;
        end else begin
            // Pipeline stage 1: latch address
            read_data_pipe <= fifo_mem[rd_ptr[$clog2(FIFO_DEPTH)-1:0]];
            read_data_valid_pipe <= rd_en && !empty;
            // Pipeline stage 2: output data
            if (read_data_valid_pipe) begin
                data_out <= read_data_pipe;
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

    // 满/空状态判断
    assign full = ((wr_ptr[$clog2(FIFO_DEPTH)] != rd_ptr[$clog2(FIFO_DEPTH)]) &&
                   (wr_ptr[$clog2(FIFO_DEPTH)-1:0] == rd_ptr[$clog2(FIFO_DEPTH)-1:0]));
    assign empty = (wr_ptr == rd_ptr);

endmodule

// Gray码跨时钟域同步器
module GraySync #(
    parameter WIDTH = 5,
    parameter STAGES = 3
)(
    input  wire clk,
    input  wire rst,
    input  wire [WIDTH-1:0] d_in,
    output reg  [WIDTH-1:0] d_out
);
    reg [WIDTH-1:0] sync_chain [0:STAGES-1];
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < STAGES; i = i + 1) begin
                sync_chain[i] <= {WIDTH{1'b0}};
            end
            d_out <= {WIDTH{1'b0}};
        end else begin
            sync_chain[0] <= d_in;
            for (i = 1; i < STAGES; i = i + 1) begin
                sync_chain[i] <= sync_chain[i-1];
            end
            d_out <= sync_chain[STAGES-1];
        end
    end

endmodule

// 奇偶校验生成模块
module ParityGen #(
    parameter DATA_WIDTH = 9
)(
    input  wire [DATA_WIDTH-2:0] data_in,
    output wire parity_bit
);
    assign parity_bit = ^data_in;
endmodule

// UART发送模块，结构化流水线分级
module UART_Tx_Pipelined #(
    parameter DATA_WIDTH = 9
)(
    input  wire clk,
    input  wire rst,
    input  wire fifo_empty,
    input  wire [DATA_WIDTH-1:0] fifo_data,
    output reg  fifo_rd_en,
    output reg  txd
);
    // Pipeline stage registers
    reg [DATA_WIDTH-1:0] tx_data_stage1;
    reg [DATA_WIDTH-1:0] tx_data_stage2;
    reg [3:0] state_stage2;
    reg [3:0] bit_cnt_stage2;
    reg fifo_rd_en_stage1;
    reg fifo_rd_en_stage2;
    reg txd_stage2;

    localparam IDLE   = 4'd0;
    localparam START  = 4'd1;
    localparam DATA   = 4'd2;
    localparam PARITY = 4'd3;
    localparam STOP   = 4'd4;

    // Pipeline stage 1: Capture FIFO read
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_data_stage1 <= 0;
            fifo_rd_en_stage1 <= 0;
        end else begin
            fifo_rd_en_stage1 <= 0;
            if (!fifo_empty) begin
                fifo_rd_en_stage1 <= 1'b1;
                tx_data_stage1 <= fifo_data;
            end
        end
    end

    // Pipeline stage 2: UART send FSM
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_stage2 <= IDLE;
            bit_cnt_stage2 <= 0;
            tx_data_stage2 <= 0;
            fifo_rd_en_stage2 <= 0;
            txd_stage2 <= 1'b1;
        end else begin
            fifo_rd_en_stage2 <= 0;
            case (state_stage2)
                IDLE: begin
                    txd_stage2 <= 1'b1;
                    if (fifo_rd_en_stage1) begin
                        fifo_rd_en_stage2 <= 1'b1;
                        tx_data_stage2 <= tx_data_stage1;
                        bit_cnt_stage2 <= 0;
                        state_stage2 <= START;
                    end
                end
                START: begin
                    txd_stage2 <= 1'b0;
                    state_stage2 <= DATA;
                end
                DATA: begin
                    txd_stage2 <= tx_data_stage2[bit_cnt_stage2];
                    if (bit_cnt_stage2 == DATA_WIDTH-2) begin
                        bit_cnt_stage2 <= 0;
                        state_stage2 <= PARITY;
                    end else begin
                        bit_cnt_stage2 <= bit_cnt_stage2 + 1;
                    end
                end
                PARITY: begin
                    txd_stage2 <= tx_data_stage2[DATA_WIDTH-1];
                    state_stage2 <= STOP;
                end
                STOP: begin
                    txd_stage2 <= 1'b1;
                    state_stage2 <= IDLE;
                end
                default: state_stage2 <= IDLE;
            endcase
        end
    end

    // Pipeline stage 3: Output
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            txd <= 1'b1;
            fifo_rd_en <= 1'b0;
        end else begin
            txd <= txd_stage2;
            fifo_rd_en <= fifo_rd_en_stage2;
        end
    end

endmodule

// UART接收模块，结构化流水线分级
module UART_Rx_Pipelined #(
    parameter DATA_WIDTH = 9
)(
    input  wire clk,
    input  wire rst,
    input  wire rxd,
    output reg  frame_error,
    output reg  parity_error
);
    // Pipeline stage registers
    reg [3:0] state_stage1;
    reg [DATA_WIDTH-1:0] rx_shift_stage1;
    reg [3:0] bit_cnt_stage1;
    reg parity_bit_calc_stage1;
    reg rxd_stage1;

    reg [3:0] state_stage2;
    reg [DATA_WIDTH-1:0] rx_shift_stage2;
    reg [3:0] bit_cnt_stage2;
    reg parity_bit_calc_stage2;
    reg rxd_stage2;
    reg frame_error_stage2;
    reg parity_error_stage2;

    localparam IDLE   = 4'd0;
    localparam START  = 4'd1;
    localparam DATA   = 4'd2;
    localparam PARITY = 4'd3;
    localparam STOP   = 4'd4;

    // Pipeline stage 1: Sample input
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_stage1 <= IDLE;
            bit_cnt_stage1 <= 0;
            rx_shift_stage1 <= 0;
            parity_bit_calc_stage1 <= 0;
            rxd_stage1 <= 1'b1;
        end else begin
            rxd_stage1 <= rxd;
            case (state_stage1)
                IDLE: begin
                    if (!rxd_stage1) begin
                        state_stage1 <= START;
                        bit_cnt_stage1 <= 0;
                    end
                end
                START: begin
                    if (!rxd_stage1) begin
                        state_stage1 <= DATA;
                    end else begin
                        state_stage1 <= IDLE;
                    end
                end
                DATA: begin
                    rx_shift_stage1[bit_cnt_stage1] <= rxd_stage1;
                    if (bit_cnt_stage1 == DATA_WIDTH-2) begin
                        bit_cnt_stage1 <= 0;
                        state_stage1 <= PARITY;
                    end else begin
                        bit_cnt_stage1 <= bit_cnt_stage1 + 1;
                    end
                end
                PARITY: begin
                    rx_shift_stage1[DATA_WIDTH-1] <= rxd_stage1;
                    parity_bit_calc_stage1 <= ^rx_shift_stage1[DATA_WIDTH-2:0];
                    state_stage1 <= STOP;
                end
                STOP: begin
                    state_stage1 <= IDLE;
                end
                default: state_stage1 <= IDLE;
            endcase
        end
    end

    // Pipeline stage 2: Error detection and output
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_stage2 <= IDLE;
            bit_cnt_stage2 <= 0;
            rx_shift_stage2 <= 0;
            parity_bit_calc_stage2 <= 0;
            rxd_stage2 <= 1'b1;
            frame_error_stage2 <= 0;
            parity_error_stage2 <= 0;
        end else begin
            state_stage2 <= state_stage1;
            bit_cnt_stage2 <= bit_cnt_stage1;
            rx_shift_stage2 <= rx_shift_stage1;
            parity_bit_calc_stage2 <= parity_bit_calc_stage1;
            rxd_stage2 <= rxd_stage1;
            frame_error_stage2 <= 0;
            parity_error_stage2 <= 0;
            if (state_stage1 == PARITY) begin
                parity_error_stage2 <= (rxd_stage1 != (^rx_shift_stage1[DATA_WIDTH-2:0]));
            end
            if (state_stage1 == STOP) begin
                if (!rxd_stage1)
                    frame_error_stage2 <= 1'b1;
            end
        end
    end

    // Output registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_error <= 0;
            parity_error <= 0;
        end else begin
            frame_error <= frame_error_stage2;
            parity_error <= parity_error_stage2;
        end
    end

endmodule