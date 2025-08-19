//SystemVerilog
module RangeDetector_WindowFSM #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] win_low,
    input [WIDTH-1:0] win_high,
    output reg cross_event
);

// 使用单bit表示状态
localparam INSIDE = 1'b0;
localparam OUTSIDE = 1'b1;

reg current_state, next_state;
wire in_range;

// 使用带符号比较直接判断范围
wire signed [WIDTH-1:0] s_data_in = data_in;
wire signed [WIDTH-1:0] s_win_low = win_low;
wire signed [WIDTH-1:0] s_win_high = win_high;

// 优化的范围检测逻辑 - 直接使用比较器
assign in_range = (s_data_in >= s_win_low) && (s_data_in <= s_win_high);

// 状态寄存器
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        current_state <= INSIDE;
    else 
        current_state <= next_state;
end

// 简化的状态转换逻辑
always @(*) begin
    next_state = in_range ? INSIDE : OUTSIDE;
end

// 边缘检测逻辑 - 保持在时钟沿触发
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        cross_event <= 1'b0;
    else
        cross_event <= (current_state != next_state);
end

endmodule