//SystemVerilog
module UART_9Bit_Address #(
    parameter ADDRESS = 8'hFF
)(
    input  wire        clk,          // 时钟信号
    input  wire        rst_n,        // 复位信号
    input  wire        addr_mode_en, // 地址模式使能
    output reg         frame_match,
    input  wire        rx_start,     // 开始信号
    input  wire        rx_bit9,      // 第9位信号
    input  wire        rx_done,      // 结束信号
    input  wire [7:0]  rx_data,      // 接收数据
    input  wire [8:0]  tx_data_9bit, // 标准接口增加第9位
    output reg  [8:0]  rx_data_9bit
);

// 地址识别状态机
localparam ADDR_IDLE  = 2'd0;
localparam ADDR_CHECK = 2'd1;
localparam DATA_PHASE = 2'd2;

// 输入同步寄存器
reg        rx_start_sync;
reg        rx_bit9_sync;
reg        rx_done_sync;
reg [7:0]  rx_data_sync;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_start_sync <= 1'b0;
        rx_bit9_sync  <= 1'b0;
        rx_done_sync  <= 1'b0;
        rx_data_sync  <= 8'd0;
    end else begin
        rx_start_sync <= rx_start;
        rx_bit9_sync  <= rx_bit9;
        rx_done_sync  <= rx_done;
        rx_data_sync  <= rx_data;
    end
end

wire rx_start_q = rx_start_sync;
wire rx_bit9_q  = rx_bit9_sync;
wire rx_done_q  = rx_done_sync;
wire [7:0] rx_data_q = rx_data_sync;

// 状态寄存器
reg [1:0] state, next_state;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        state <= ADDR_IDLE;
    else
        state <= next_state;
end

// 目标地址寄存器
reg [7:0] target_addr;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        target_addr <= ADDRESS;
    else
        target_addr <= target_addr; // 保持不变
end

// 地址标志位寄存器（保留，便于功能扩展）
reg addr_flag;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        addr_flag <= 1'b0;
    else
        addr_flag <= addr_flag; // 保持不变
end

// 状态机组合逻辑
always @(*) begin
    next_state = state;
    case(state)
        ADDR_IDLE: begin
            if (addr_mode_en && rx_start_q && rx_bit9_q) begin
                next_state = ADDR_CHECK;
            end
        end
        ADDR_CHECK: begin
            if (addr_mode_en && rx_done_q) begin
                if (rx_data_q == target_addr)
                    next_state = DATA_PHASE;
                else
                    next_state = ADDR_IDLE;
            end
        end
        DATA_PHASE: begin
            if (addr_mode_en && rx_done_q) begin
                if (!rx_bit9_q)
                    next_state = DATA_PHASE;
                else
                    next_state = ADDR_CHECK;
            end
        end
        default: next_state = ADDR_IDLE;
    endcase
end

// frame_match逻辑
reg frame_match_next;
always @(*) begin
    frame_match_next = frame_match;
    case(state)
        ADDR_IDLE: begin
            if (addr_mode_en && rx_start_q && rx_bit9_q) begin
                frame_match_next = 1'b0;
            end
        end
        ADDR_CHECK: begin
            if (addr_mode_en && rx_done_q) begin
                frame_match_next = (rx_data_q == target_addr);
            end
        end
        default: ;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        frame_match <= 1'b0;
    else
        frame_match <= frame_match_next;
end

// rx_data_9bit逻辑
reg [8:0] rx_data_9bit_next;
always @(*) begin
    rx_data_9bit_next = rx_data_9bit;
    if (state == DATA_PHASE && addr_mode_en && rx_done_q) begin
        rx_data_9bit_next = {rx_bit9_q, rx_data_q};
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rx_data_9bit <= 9'd0;
    else
        rx_data_9bit <= rx_data_9bit_next;
end

// 数据位扩展逻辑
wire [8:0] tx_packet;
assign tx_packet = {addr_flag, tx_data_9bit[7:0]};

endmodule