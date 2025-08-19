//SystemVerilog
module SobelEdge #(parameter W=8) (
    input clk,
    input [W-1:0] pixel_in,
    output reg [W+1:0] gradient
);
    reg [W-1:0] window [0:8];
    reg [W+1:0] sum1, sum2;
    reg [W+1:0] term1, term2;
    integer i;
    
    always @(posedge clk) begin
        // 手动移位窗口
        for(i=8; i>0; i=i-1)
            window[i] <= window[i-1];
        window[0] <= pixel_in;
        
        // 第一阶段流水线：计算各项和
        term1 <= window[0] + (window[3] << 1);
        term2 <= window[2] + (window[5] << 1);
        
        // 第二阶段流水线：完成各自的和
        sum1 <= term1 + window[6];
        sum2 <= term2 + window[8];
        
        // 第三阶段流水线：计算最终梯度
        gradient <= sum1 - sum2;
    end
endmodule