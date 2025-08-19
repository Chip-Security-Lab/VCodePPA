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

// 状态定义
localparam STATE_INSIDE = 1'b0;
localparam STATE_OUTSIDE = 1'b1;

// 流水线寄存器
reg [WIDTH-1:0] data_in_reg, win_low_reg, win_high_reg;
reg [WIDTH-1:0] data_minus_low_reg, high_minus_data_reg;
reg is_less_than_low_reg, is_greater_than_high_reg;
reg is_outside_window_reg;
reg current_state, next_state;

// 第一级流水线：寄存输入
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_in_reg <= {WIDTH{1'b0}};
        win_low_reg <= {WIDTH{1'b0}};
        win_high_reg <= {WIDTH{1'b0}};
    end else begin
        data_in_reg <= data_in;
        win_low_reg <= win_low;
        win_high_reg <= win_high;
    end
end

// 第二级流水线：计算差值
wire [WIDTH-1:0] data_minus_low = data_in_reg + (~win_low_reg + 1'b1);
wire [WIDTH-1:0] high_minus_data = win_high_reg + (~data_in_reg + 1'b1);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_minus_low_reg <= {WIDTH{1'b0}};
        high_minus_data_reg <= {WIDTH{1'b0}};
    end else begin
        data_minus_low_reg <= data_minus_low;
        high_minus_data_reg <= high_minus_data;
    end
end

// 第三级流水线：判断边界条件
wire is_less_than_low = data_minus_low_reg[WIDTH-1];
wire is_greater_than_high = high_minus_data_reg[WIDTH-1];
wire is_outside_window = is_less_than_low || is_greater_than_high;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        is_less_than_low_reg <= 1'b0;
        is_greater_than_high_reg <= 1'b0;
        is_outside_window_reg <= 1'b0;
    end else begin
        is_less_than_low_reg <= is_less_than_low;
        is_greater_than_high_reg <= is_greater_than_high;
        is_outside_window_reg <= is_outside_window;
    end
end

// 第四级流水线：状态机逻辑
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        current_state <= STATE_INSIDE;
    else 
        current_state <= next_state;
end

always @(*) begin
    case (current_state)
        STATE_INSIDE:  next_state = is_outside_window_reg ? STATE_OUTSIDE : STATE_INSIDE;
        STATE_OUTSIDE: next_state = !is_outside_window_reg ? STATE_INSIDE : STATE_OUTSIDE;
        default:       next_state = STATE_INSIDE;
    endcase
end

// 第五级流水线：事件检测输出
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cross_event <= 1'b0;
    else
        cross_event <= (current_state != next_state);
end

endmodule