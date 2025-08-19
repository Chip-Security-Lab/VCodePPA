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
    reg prev_state;
    wire current_state;
    
    // 将组合逻辑提前计算，减少输入到第一级寄存器的延迟
    assign current_state = (data_in >= threshold);
    
    // 状态更新模块 - 专注于状态存储
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_state <= 1'b0;
        end else begin
            prev_state <= current_state;
        end
    end
    
    // 上升沿检测模块 - 专注于捕获上升沿
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rise_detected <= 1'b0;
        end else begin
            rise_detected <= !prev_state && current_state;
        end
    end
    
    // 下降沿检测模块 - 专注于捕获下降沿
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fall_detected <= 1'b0;
        end else begin
            fall_detected <= prev_state && !current_state;
        end
    end
endmodule