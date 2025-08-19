//SystemVerilog
`timescale 1ns/1ps
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

// 状态编码优化为独热码，减少比较逻辑深度
localparam ADDR_IDLE  = 3'b001;
localparam ADDR_CHECK = 3'b010;
localparam DATA_PHASE = 3'b100;

reg [2:0] state, state_next;

// 地址匹配寄存器
reg [7:0] target_addr;
reg       addr_flag;

// 预先计算的匹配信号，减少状态机组合深度
wire      rx_addr_match;
assign    rx_addr_match = (rx_data == target_addr);

// 优化状态转移条件，减少级联判断
always @(*) begin
    state_next = state;
    case (state)
        ADDR_IDLE: begin
            if (rx_start && rx_bit9)
                state_next = ADDR_CHECK;
        end
        ADDR_CHECK: begin
            if (rx_done) begin
                if (rx_addr_match)
                    state_next = DATA_PHASE;
                else
                    state_next = ADDR_IDLE;
            end
        end
        DATA_PHASE: begin
            if (rx_done) begin
                if (rx_bit9)
                    state_next = ADDR_CHECK;
                else
                    state_next = DATA_PHASE;
            end
        end
        default: state_next = ADDR_IDLE;
    endcase
end

// 优化frame_match计算，消除关键路径
reg frame_match_next;
always @(*) begin
    frame_match_next = frame_match;
    if (state == ADDR_CHECK && rx_done)
        frame_match_next = rx_addr_match;
    else if (state == ADDR_IDLE && rx_start && rx_bit9)
        frame_match_next = 1'b0;
end

// 优化数据拼接与输出
reg [8:0] rx_data_9bit_next;
always @(*) begin
    rx_data_9bit_next = rx_data_9bit;
    if (state == DATA_PHASE && rx_done)
        rx_data_9bit_next = {rx_bit9, rx_data};
end

// addr_flag 逻辑简化，便于后续扩展
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state        <= ADDR_IDLE;
        frame_match  <= 1'b0;
        target_addr  <= ADDRESS;
        rx_data_9bit <= 9'b0;
        addr_flag    <= 1'b0;
    end else if (addr_mode_en) begin
        state        <= state_next;
        frame_match  <= frame_match_next;
        rx_data_9bit <= rx_data_9bit_next;
        addr_flag    <= (state_next == DATA_PHASE);
    end
end

// 数据位扩展逻辑（保持为组合逻辑，消除级联）
wire [8:0] tx_packet;
assign tx_packet = {addr_flag, tx_data_9bit[7:0]};

endmodule