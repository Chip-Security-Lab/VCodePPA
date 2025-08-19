//SystemVerilog
module RangeDetector_DualEdge #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] threshold,
    output reg rise_detected,
    output reg fall_detected
);
    // 使用单一的比较结果信号，减少重复比较操作
    reg above_threshold;
    reg prev_above_threshold;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            above_threshold <= 1'b0;
            prev_above_threshold <= 1'b0;
            rise_detected <= 1'b0;
            fall_detected <= 1'b0;
        end
        else begin
            // 执行一次比较，保存结果
            above_threshold <= (data_in >= threshold);
            prev_above_threshold <= above_threshold;
            
            // 根据保存的比较结果检测上升沿和下降沿
            rise_detected <= (!prev_above_threshold && above_threshold);
            fall_detected <= (prev_above_threshold && !above_threshold);
        end
    end
endmodule