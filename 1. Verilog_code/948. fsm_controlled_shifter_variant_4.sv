//SystemVerilog
module fsm_controlled_shifter (
    input clk, rst, start,
    input [31:0] data,
    input [4:0] total_shift,
    output reg done,
    output reg [31:0] result
);
// 用参数定义状态常量
localparam IDLE = 1'b0;
localparam SHIFT = 1'b1;

reg state, next_state; // 状态寄存器
reg [4:0] cnt, next_cnt;
reg [31:0] next_result;
reg next_done;

// 状态寄存器更新
always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= IDLE;
        cnt <= 5'b0;
        result <= 32'b0;
        done <= 1'b0;
    end else begin
        state <= next_state;
        cnt <= next_cnt;
        result <= next_result;
        done <= next_done;
    end
end

// 组合逻辑，计算下一状态
always @(*) begin
    next_state = state;
    case(state)
        IDLE: if (start) next_state = SHIFT;
        SHIFT: if (cnt == 5'd1 || cnt == 5'd0) next_state = IDLE;
        default: next_state = IDLE;
    endcase
end

// 组合逻辑，计算计数器的下一个值
always @(*) begin
    next_cnt = cnt;
    case(state)
        IDLE: if (start) next_cnt = total_shift;
        SHIFT: if (|cnt) next_cnt = cnt - 5'd1;
        default: next_cnt = 5'b0;
    endcase
end

// 组合逻辑，计算结果的下一个值
always @(*) begin
    next_result = result;
    case(state)
        IDLE: if (start) next_result = data;
        SHIFT: if (|cnt) next_result = result << 1;
        default: next_result = result;
    endcase
end

// 组合逻辑，计算完成信号的下一个值
always @(*) begin
    next_done = done;
    case(state)
        IDLE: next_done = 1'b0;
        SHIFT: if (cnt == 5'd1 || cnt == 5'd0) next_done = 1'b1;
        default: next_done = 1'b0;
    endcase
end

endmodule