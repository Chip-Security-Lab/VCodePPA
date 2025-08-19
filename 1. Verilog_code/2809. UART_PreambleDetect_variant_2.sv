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

reg [7:0] shift_reg;
reg [3:0] match_count;
wire [3:0] match_count_inc;
wire preamble_detected;
reg preamble_valid_next;
reg rx_enable_next;

// 前导码检测
assign preamble_detected = (shift_reg == PREAMBLE);

Adder4b match_counter_adder_inst (
    .a   (match_count),
    .b   (4'b0001),
    .sum (match_count_inc)
);

always @(*) begin
    // 路径平衡优化：将组合逻辑层级均衡分布
    // 先判断preamble_detected，再计算preamble_valid_next和rx_enable_next
    if (preamble_detected) begin
        preamble_valid_next = (match_count_inc >= PRE_LEN);
    end else begin
        preamble_valid_next = 1'b0;
    end

    if (preamble_detected && (match_count_inc >= PRE_LEN)) begin
        rx_enable_next = 1'b1;
    end else if (rx_done) begin
        rx_enable_next = 1'b0;
    end else begin
        rx_enable_next = rx_enable;
    end
end

always @(posedge clk) begin
    // 移位寄存器
    shift_reg <= {shift_reg[6:0], rxd};

    // 匹配计数器
    if (preamble_detected) begin
        match_count <= match_count_inc;
    end else begin
        match_count <= 4'b0000;
    end

    // 前导码有效信号
    preamble_valid <= preamble_valid_next;

    // 接收使能逻辑
    rx_enable <= rx_enable_next;
end

endmodule

module Adder4b (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output wire [3:0] sum
);
    // 路径平衡优化：采用简单加法器替代复杂进位链
    assign sum = a + b;
endmodule