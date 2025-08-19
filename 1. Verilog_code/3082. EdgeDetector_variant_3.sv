//SystemVerilog
module EdgeDetector #(
    parameter PULSE_WIDTH = 2
)(
    input clk, rst_async,
    input signal_in,
    output reg rising_edge,
    output reg falling_edge
);

    // 使用单比特寄存器减少资源使用
    reg signal_prev;
    wire signal_curr;
    
    // 同步输入信号
    always @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            signal_prev <= 1'b0;
        end else begin
            signal_prev <= signal_in;
        end
    end
    
    // 直接使用同步后的信号
    assign signal_curr = signal_in;
    
    // 优化边沿检测逻辑,减少组合逻辑延迟
    wire rising_detect = ~signal_prev & signal_curr;
    wire falling_detect = signal_prev & ~signal_curr;
    
    // 输出寄存器
    always @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            rising_edge <= 1'b0;
            falling_edge <= 1'b0;
        end else begin
            rising_edge <= rising_detect;
            falling_edge <= falling_detect;
        end
    end

endmodule