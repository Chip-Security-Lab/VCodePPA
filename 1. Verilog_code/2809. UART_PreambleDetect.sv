module UART_PreambleDetect #(
    parameter PREAMBLE = 8'hAA,
    parameter PRE_LEN  = 4
)(
    input wire clk,           // 添加时钟输入
    input wire rxd,           // 添加接收数据输入
    input wire rx_done,       // 添加接收完成信号
    output reg rx_enable,     // 添加接收使能输出
    output reg preamble_valid // 前导码有效标志
);
// 移位寄存器检测器
reg [7:0] preamble_shift;
reg [3:0] match_counter;

always @(posedge clk) begin
    preamble_shift <= {preamble_shift[6:0], rxd};

    if (preamble_shift == PREAMBLE) begin
        match_counter <= match_counter + 1;
    end else begin
        match_counter <= 0;
    end

    preamble_valid <= (match_counter >= PRE_LEN);
end

// 同步触发机制
always @(posedge clk) begin
    if (preamble_valid)
        rx_enable <= 1'b1;
    else if (rx_done)
        rx_enable <= 1'b0;
end
endmodule