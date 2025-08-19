//SystemVerilog
// 顶层模块
module async_debounce_filter #(
    parameter STABLE_COUNT = 8
)(
    input noisy_signal,
    input [3:0] curr_state,
    output [3:0] next_state,
    output clean_signal
);
    // 子模块实例化
    counter_logic #(
        .STABLE_COUNT(STABLE_COUNT)
    ) counter_unit (
        .noisy_signal(noisy_signal),
        .curr_state(curr_state),
        .next_state(next_state)
    );
    
    threshold_detector #(
        .STABLE_COUNT(STABLE_COUNT)
    ) detector_unit (
        .curr_state(curr_state),
        .clean_signal(clean_signal)
    );
endmodule

// 计数器逻辑子模块 - 优化比较链和条件逻辑
module counter_logic #(
    parameter STABLE_COUNT = 8
)(
    input noisy_signal,
    input [3:0] curr_state,
    output reg [3:0] next_state
);
    // 使用参数化常量，方便后续修改
    localparam [3:0] MAX_COUNT = STABLE_COUNT;
    
    always @(*) begin
        // 默认情况，保持状态不变
        next_state = curr_state;
        
        // 两种条件分开写，避免复杂的嵌套条件，优化比较器使用
        if (noisy_signal) begin
            // 只有当计数未达到最大值时才增加
            if (curr_state < MAX_COUNT)
                next_state = curr_state + 1'b1;
        end
        else begin
            // 只有当计数不为零时才减少
            if (|curr_state) // 使用归约操作符，比 > 0 更高效
                next_state = curr_state - 1'b1;
        end
    end
endmodule

// 阈值检测子模块 - 优化比较逻辑
module threshold_detector #(
    parameter STABLE_COUNT = 8
)(
    input [3:0] curr_state,
    output clean_signal
);
    // 优化的阈值比较逻辑，使用位运算提高效率
    localparam [3:0] THRESHOLD = STABLE_COUNT/2;
    
    // 提取最关键的比较位，减少比较器资源
    wire msb_check = curr_state[3:2] != 2'b00;
    
    // 使用高位检测和精确比较的组合
    assign clean_signal = msb_check || (curr_state >= THRESHOLD);
endmodule