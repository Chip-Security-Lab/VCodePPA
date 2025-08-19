//SystemVerilog
module UART_BreakDetect #(
    parameter BREAK_MIN = 16  // 最小Break时钟数
)(
    input wire clk,
    input wire rxd,
    output reg break_event,
    output reg [15:0] break_duration
);

// 低电平持续时间计数器
reg [15:0] low_counter;
reg rxd_last;
reg [2:0] break_filter;

always @(posedge clk) begin
    // 输入采样和消抖寄存器
    rxd_last <= rxd;
    break_filter <= {break_filter[1:0], rxd};

    // 低电平计数与break事件检测
    if (rxd == 1'b0) begin
        low_counter <= low_counter + 1;
    end else begin
        if (low_counter > BREAK_MIN) begin
            break_event <= 1'b1;
            break_duration <= low_counter;
        end
        low_counter <= 0;
    end

    // break_event消抖处理
    if (break_filter[2] & break_filter[1]) begin
        break_event <= 1'b0;
    end
end

endmodule