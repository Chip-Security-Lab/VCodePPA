//SystemVerilog
// 顶层模块
module debounced_reset #(
    parameter DEBOUNCE_COUNT = 3
)(
    input  wire clk,
    input  wire noisy_reset,
    output wire clean_reset
);
    // 内部信号定义
    wire edge_detected;
    wire count_complete;
    wire [1:0] count_value;
    wire reset_ff;

    // 子模块实例化
    edge_detector u_edge_detector (
        .reset_ff     (reset_ff),
        .noisy_reset  (noisy_reset),
        .edge_detected(edge_detected)
    );

    counter_control u_counter_control (
        .clk           (clk),
        .edge_detected (edge_detected),
        .count_complete(count_complete),
        .count_value   (count_value)
    );

    output_controller u_output_controller (
        .clk           (clk),
        .reset_ff      (reset_ff),
        .count_complete(count_complete),
        .clean_reset   (clean_reset)
    );

    synchronizer u_synchronizer (
        .clk         (clk),
        .noisy_reset (noisy_reset),
        .reset_ff    (reset_ff)
    );

endmodule

// 输入同步器子模块
module synchronizer (
    input  wire clk,
    input  wire noisy_reset,
    output reg  reset_ff
);
    // 只包含时序逻辑
    always @(posedge clk) begin
        reset_ff <= noisy_reset;
    end
endmodule

// 边沿检测器子模块
module edge_detector (
    input  wire reset_ff,
    input  wire noisy_reset,
    output wire edge_detected
);
    // 纯组合逻辑
    assign edge_detected = (reset_ff != noisy_reset);
endmodule

// 计数器控制子模块
module counter_control #(
    parameter DEBOUNCE_COUNT = 3
)(
    input  wire clk,
    input  wire edge_detected,
    output wire count_complete,
    output reg  [1:0] count_value
);
    // 组合逻辑部分
    wire [1:0] next_count_value;
    
    // 纯组合逻辑: 决定下一个计数值
    assign next_count_value = edge_detected ? 2'b00 :
                             (!count_complete) ? (count_value + 1'b1) :
                             count_value;
    
    // 纯组合逻辑: 确定计数是否完成
    assign count_complete = (count_value >= DEBOUNCE_COUNT);

    // 时序逻辑部分
    always @(posedge clk) begin
        count_value <= next_count_value;
    end
endmodule

// 输出控制器子模块
module output_controller (
    input  wire clk,
    input  wire reset_ff,
    input  wire count_complete,
    output reg  clean_reset
);
    // 组合逻辑部分
    wire next_clean_reset;
    
    // 纯组合逻辑: 决定下一个清洁复位信号
    assign next_clean_reset = count_complete ? reset_ff : clean_reset;
    
    // 时序逻辑部分
    always @(posedge clk) begin
        clean_reset <= next_clean_reset;
    end
endmodule