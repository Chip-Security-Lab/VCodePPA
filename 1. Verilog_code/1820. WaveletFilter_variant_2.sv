//SystemVerilog
module WaveletFilter #(parameter W=8) (
    input clk,
    input [W-1:0] din,
    output reg [W-1:0] approx,
    output reg [W-1:0] detail
);
    // 直接存储当前和前一个输入样本
    reg [W-1:0] current_sample;
    reg [W-1:0] prev_sample;
    
    // 存储当前和前一个样本
    always @(posedge clk) begin
        current_sample <= din;
        prev_sample <= current_sample;
    end
    
    // 计算近似系数和细节系数
    always @(posedge clk) begin
        approx <= (current_sample + prev_sample) >> 1;
        detail <= current_sample - prev_sample;
    end
endmodule