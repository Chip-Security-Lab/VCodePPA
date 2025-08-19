//SystemVerilog
/* IEEE 1364-2005 Verilog Standard */
module counter_reset_gen #(
    parameter THRESHOLD = 10
)(
    input wire clk,
    input wire enable,
    output reg reset_out
);
    // 优化后的流水线寄存器
    reg [3:0] counter;
    reg counter_reached_threshold;
    reg counter_reached_threshold_stage1;
    reg counter_reached_threshold_stage2;
    
    // 计数器逻辑 - 将组合逻辑提前，寄存器后移
    wire [3:0] next_counter = (!enable) ? 4'b0 : 
                              (counter < THRESHOLD) ? counter + 1'b1 : counter;
    
    // 阈值检测组合逻辑
    wire next_threshold_reached = (next_counter == THRESHOLD);
    
    // 第一级流水线：合并计数和阈值检测
    always @(posedge clk) begin
        counter <= next_counter;
        counter_reached_threshold <= next_threshold_reached;
    end
    
    // 第二级流水线
    always @(posedge clk) begin
        counter_reached_threshold_stage1 <= counter_reached_threshold;
    end
    
    // 第三级流水线
    always @(posedge clk) begin
        counter_reached_threshold_stage2 <= counter_reached_threshold_stage1;
    end
    
    // 第四级流水线：输出生成
    always @(posedge clk) begin
        reset_out <= counter_reached_threshold_stage2;
    end
endmodule