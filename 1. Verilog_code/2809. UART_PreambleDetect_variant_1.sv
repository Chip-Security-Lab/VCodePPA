//SystemVerilog
module UART_PreambleDetect #(
    parameter PREAMBLE = 8'hAA,
    parameter PRE_LEN  = 4
)(
    input wire clk,
    input wire rxd,
    input wire rx_done,
    output reg rx_enable,
    output reg preamble_valid
);

// 移位寄存器检测器
reg [7:0] preamble_shift;
reg [3:0] match_counter_d, match_counter_q;
reg preamble_match_d, preamble_match_q;
reg preamble_valid_d, preamble_valid_q;

// 移动寄存器到组合逻辑前，实现后向重定时
always @(posedge clk) begin
    preamble_shift <= {preamble_shift[6:0], rxd};
    match_counter_q <= match_counter_d;
    preamble_match_q <= preamble_match_d;
    preamble_valid_q <= preamble_valid_d;
end

// 组合逻辑
always @* begin
    // 检查是否匹配前导码
    preamble_match_d = (preamble_shift == PREAMBLE);

    // 匹配计数器逻辑，使用case语句代替if-else
    case (preamble_match_q)
        1'b1: match_counter_d = match_counter_q + 1;
        1'b0: match_counter_d = 0;
        default: match_counter_d = 0;
    endcase

    // 前导码有效标志逻辑，使用case语句代替if-else
    case (match_counter_q >= PRE_LEN)
        1'b1: preamble_valid_d = 1'b1;
        1'b0: preamble_valid_d = 1'b0;
        default: preamble_valid_d = 1'b0;
    endcase
end

// 输出寄存器
always @(posedge clk) begin
    preamble_valid <= preamble_valid_q;
end

// 同步触发机制，使用case语句代替if-else
always @(posedge clk) begin
    case ({preamble_valid_q, rx_done})
        2'b10: rx_enable <= 1'b1;
        2'b01: rx_enable <= 1'b0;
        default: rx_enable <= rx_enable;
    endcase
end

endmodule