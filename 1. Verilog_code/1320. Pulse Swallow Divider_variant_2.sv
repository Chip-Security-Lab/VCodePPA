//SystemVerilog
module pulse_swallow_div (
    input clk_in, reset, swallow_en,
    input [3:0] swallow_val,
    output reg clk_out
);
    // 预计算常量表达式
    localparam MAX_COUNT = 4'd7;
    
    reg [3:0] counter;
    reg swallow;
    
    // 优化后的时序逻辑
    always @(posedge clk_in) begin
        if (reset) begin
            counter <= 4'd0;
            clk_out <= 1'b0;
            swallow <= 1'b0;
        end else begin
            // 使用单一加法器和优化的条件逻辑
            if (counter == MAX_COUNT) begin
                counter <= 4'd0;
                clk_out <= ~clk_out;
                swallow <= 1'b0;
            end else if (swallow) begin
                // 已经吞掉一个脉冲，保持计数器不变
                counter <= counter;
            end else if (swallow_en && (counter == swallow_val)) begin
                // 触发吞噬条件
                counter <= counter + 1'b1;
                swallow <= 1'b1;
            end else begin
                // 正常计数
                counter <= counter + 1'b1;
            end
        end
    end
endmodule