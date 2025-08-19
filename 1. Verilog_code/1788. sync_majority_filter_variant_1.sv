//SystemVerilog
module async_debounce_filter #(
    parameter STABLE_COUNT = 8,
    parameter THRESHOLD = STABLE_COUNT/2
)(
    input noisy_signal,
    input [3:0] curr_state,
    output reg [3:0] next_state,
    output clean_signal
);
    // 优化比较逻辑，减少比较操作，提高资源利用效率
    wire at_max = (curr_state == STABLE_COUNT);
    wire at_zero = (curr_state == 0);
    
    always @(*) begin
        casez({noisy_signal, at_max, at_zero})
            3'b10?: next_state = curr_state + 1'b1; // 信号为1且未达到最大值
            3'b01?: next_state = curr_state;        // 信号为0但已达到最大值或信号为1且已达到最大值
            3'b001: next_state = curr_state;        // 信号为0且已经是0
            3'b000: next_state = curr_state - 1'b1; // 信号为0且不是0
            default: next_state = curr_state;
        endcase
    end
    
    // 使用参数化阈值，避免每次重新计算
    assign clean_signal = (curr_state >= THRESHOLD);
endmodule