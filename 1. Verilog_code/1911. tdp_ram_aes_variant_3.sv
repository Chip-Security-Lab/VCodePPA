//SystemVerilog
module AdaptiveThreshold #(
    parameter WIDTH = 8,
    parameter ALPHA = 3
)(
    input wire clk,
    input wire [WIDTH-1:0] adc_input,
    output reg digital_out
);
    // 扩展位宽，确保计算精度
    reg [WIDTH+ALPHA-1:0] avg_level;
    reg [WIDTH-1:0] threshold;
    
    // 平均值更新块
    always @(posedge clk) begin
        avg_level <= avg_level + {{ALPHA{adc_input[WIDTH-1]}}, adc_input} - threshold;
    end
    
    // 阈值计算块
    always @(posedge clk) begin
        threshold <= avg_level >> ALPHA;
    end
    
    // 数字输出比较块
    always @(posedge clk) begin
        digital_out <= adc_input > threshold;
    end
endmodule