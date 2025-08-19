module UART_BreakDetect #(
    parameter BREAK_MIN = 16  // 最小Break时钟数
)(
    input wire clk,          // 添加时钟输入
    input wire rxd,          // 添加接收数据输入
    output reg break_event,
    output reg [15:0] break_duration
);
// 低电平持续时间计数器
reg [15:0] low_counter;
reg rxd_last;

always @(posedge clk) begin
    rxd_last <= rxd;
    
    if (rxd == 1'b0) begin
        low_counter <= low_counter + 1;
    end else begin
        if (low_counter > BREAK_MIN) begin
            break_event <= 1'b1;
            break_duration <= low_counter;
        end
        low_counter <= 0;
    end
end

// 消抖逻辑
reg [2:0] break_filter;
always @(posedge clk) begin
    break_filter <= {break_filter[1:0], rxd};
    if (break_filter[2] & break_filter[1])
        break_event <= 1'b0;
end
endmodule