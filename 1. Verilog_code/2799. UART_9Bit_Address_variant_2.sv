//SystemVerilog
module UART_9Bit_Address #(
    parameter ADDRESS = 8'hFF
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        addr_mode_en,
    output reg         frame_match,
    input  wire        rx_start,
    input  wire        rx_bit9,
    input  wire        rx_done,
    input  wire [7:0]  rx_data,
    input  wire [8:0]  tx_data_9bit,
    output reg  [8:0]  rx_data_9bit
);

// 状态定义
localparam ADDR_IDLE  = 2'd0;
localparam ADDR_CHECK = 2'd1;
localparam DATA_PHASE = 2'd2;

// 流水线级寄存器定义
reg [1:0]  state_stage1, state_stage2, state_stage3;
reg        frame_match_stage1, frame_match_stage2, frame_match_stage3;
reg [7:0]  target_addr_stage1, target_addr_stage2, target_addr_stage3;
reg        addr_flag_stage1, addr_flag_stage2, addr_flag_stage3;
reg        rx_start_stage1, rx_start_stage2, rx_start_stage3;
reg        rx_bit9_stage1, rx_bit9_stage2, rx_bit9_stage3;
reg        rx_done_stage1, rx_done_stage2, rx_done_stage3;
reg [7:0]  rx_data_stage1, rx_data_stage2, rx_data_stage3;
reg [8:0]  rx_data_9bit_stage1, rx_data_9bit_stage2, rx_data_9bit_stage3;
reg        addr_mode_en_stage1, addr_mode_en_stage2, addr_mode_en_stage3;

// 顶层输出寄存器
reg [8:0]  rx_data_9bit_out;
reg        frame_match_out;

// 初始目标地址
wire [7:0] target_addr_init;
assign target_addr_init = ADDRESS;

// 状态机流水线第1级：输入采样及状态转发
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_stage1         <= ADDR_IDLE;
        frame_match_stage1   <= 1'b0;
        target_addr_stage1   <= target_addr_init;
        addr_flag_stage1     <= 1'b0;
        rx_start_stage1      <= 1'b0;
        rx_bit9_stage1       <= 1'b0;
        rx_done_stage1       <= 1'b0;
        rx_data_stage1       <= 8'd0;
        rx_data_9bit_stage1  <= 9'd0;
        addr_mode_en_stage1  <= 1'b0;
    end else begin
        rx_start_stage1      <= rx_start;
        rx_bit9_stage1       <= rx_bit9;
        rx_done_stage1       <= rx_done;
        rx_data_stage1       <= rx_data;
        rx_data_9bit_stage1  <= tx_data_9bit;
        addr_mode_en_stage1  <= addr_mode_en;
        state_stage1         <= state_stage2;
        frame_match_stage1   <= frame_match_stage2;
        target_addr_stage1   <= target_addr_stage2;
        addr_flag_stage1     <= addr_flag_stage2;
    end
end

// 状态机流水线第2级：状态转移与复杂匹配切割
reg addr_check_match_stage2;
reg [1:0] next_state_stage2;
reg frame_match_next_stage2;

always @(*) begin
    addr_check_match_stage2 = 1'b0;
    next_state_stage2 = state_stage1;
    frame_match_next_stage2 = frame_match_stage1;
    if (addr_mode_en_stage1) begin
        case (state_stage1)
            ADDR_IDLE: begin
                if (rx_start_stage1 && rx_bit9_stage1) begin
                    next_state_stage2 = ADDR_CHECK;
                    frame_match_next_stage2 = 1'b0;
                end else begin
                    next_state_stage2 = ADDR_IDLE;
                    frame_match_next_stage2 = 1'b0;
                end
            end
            ADDR_CHECK: begin
                if (rx_done_stage1) begin
                    addr_check_match_stage2 = (rx_data_stage1 == target_addr_stage1);
                    if (rx_data_stage1 == target_addr_stage1) begin
                        frame_match_next_stage2 = 1'b1;
                        next_state_stage2 = DATA_PHASE;
                    end else begin
                        frame_match_next_stage2 = 1'b0;
                        next_state_stage2 = ADDR_IDLE;
                    end
                end else begin
                    next_state_stage2 = ADDR_CHECK;
                    frame_match_next_stage2 = frame_match_stage1;
                end
            end
            DATA_PHASE: begin
                if (rx_done_stage1) begin
                    if (!rx_bit9_stage1) begin
                        next_state_stage2 = DATA_PHASE;
                    end else begin
                        next_state_stage2 = ADDR_CHECK;
                    end
                    frame_match_next_stage2 = frame_match_stage1;
                end else begin
                    next_state_stage2 = DATA_PHASE;
                    frame_match_next_stage2 = frame_match_stage1;
                end
            end
            default: begin
                next_state_stage2 = ADDR_IDLE;
                frame_match_next_stage2 = 1'b0;
            end
        endcase
    end else begin
        next_state_stage2 = state_stage1;
        frame_match_next_stage2 = frame_match_stage1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_stage2         <= ADDR_IDLE;
        frame_match_stage2   <= 1'b0;
        target_addr_stage2   <= target_addr_init;
        addr_flag_stage2     <= 1'b0;
        rx_start_stage2      <= 1'b0;
        rx_bit9_stage2       <= 1'b0;
        rx_done_stage2       <= 1'b0;
        rx_data_stage2       <= 8'd0;
        rx_data_9bit_stage2  <= 9'd0;
        addr_mode_en_stage2  <= 1'b0;
    end else begin
        rx_start_stage2      <= rx_start_stage1;
        rx_bit9_stage2       <= rx_bit9_stage1;
        rx_done_stage2       <= rx_done_stage1;
        rx_data_stage2       <= rx_data_stage1;
        rx_data_9bit_stage2  <= rx_data_9bit_stage1;
        addr_mode_en_stage2  <= addr_mode_en_stage1;
        target_addr_stage2   <= target_addr_stage1;
        addr_flag_stage2     <= addr_flag_stage1;
        state_stage2         <= next_state_stage2;
        frame_match_stage2   <= frame_match_next_stage2;
    end
end

// 插入流水线第3级：将数据输出和状态进一步解耦，保证所有路径延迟一致
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_stage3         <= ADDR_IDLE;
        frame_match_stage3   <= 1'b0;
        target_addr_stage3   <= target_addr_init;
        addr_flag_stage3     <= 1'b0;
        rx_start_stage3      <= 1'b0;
        rx_bit9_stage3       <= 1'b0;
        rx_done_stage3       <= 1'b0;
        rx_data_stage3       <= 8'd0;
        rx_data_9bit_stage3  <= 9'd0;
        addr_mode_en_stage3  <= 1'b0;
    end else begin
        state_stage3         <= state_stage2;
        frame_match_stage3   <= frame_match_stage2;
        target_addr_stage3   <= target_addr_stage2;
        addr_flag_stage3     <= addr_flag_stage2;
        rx_start_stage3      <= rx_start_stage2;
        rx_bit9_stage3       <= rx_bit9_stage2;
        rx_done_stage3       <= rx_done_stage2;
        rx_data_stage3       <= rx_data_stage2;
        rx_data_9bit_stage3  <= rx_data_9bit_stage2;
        addr_mode_en_stage3  <= addr_mode_en_stage2;
    end
end

// 流水线第4级：输出寄存器和数据扩展
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_data_9bit_out <= 9'd0;
        frame_match_out  <= 1'b0;
    end else begin
        frame_match_out  <= frame_match_stage3;
        if (addr_mode_en_stage3 && (state_stage3 == DATA_PHASE) && rx_done_stage3) begin
            rx_data_9bit_out <= {rx_bit9_stage3, rx_data_stage3};
        end else begin
            rx_data_9bit_out <= rx_data_9bit_out;
        end
    end
end

// 顶层输出连接
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_data_9bit <= 9'd0;
        frame_match  <= 1'b0;
    end else begin
        rx_data_9bit <= rx_data_9bit_out;
        frame_match  <= frame_match_out;
    end
end

// 数据位扩展逻辑
wire [8:0] tx_packet;
assign tx_packet = {addr_flag_stage3, tx_data_9bit[7:0]};

endmodule