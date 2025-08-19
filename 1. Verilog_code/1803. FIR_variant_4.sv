//SystemVerilog
module FIR #(parameter W=8) (
    input clk, 
    input [W-1:0] sample,
    output reg [W+3:0] y
);
    parameter [3:0] COEFFS = 4'hA;
    
    reg [W-1:0] delay_line [0:3];
    reg [W+3:0] partial_sum_0, partial_sum_1;
    integer i;
    
    always @(posedge clk) begin
        // 移位延迟线
        for(i=3; i>0; i=i-1)
            delay_line[i] <= delay_line[i-1];
        delay_line[0] <= sample;
        
        // 第一阶段：计算部分和
        partial_sum_0 <= (delay_line[3] * COEFFS[3]) + (delay_line[2] * COEFFS[2]);
        partial_sum_1 <= (delay_line[1] * COEFFS[1]) + (delay_line[0] * COEFFS[0]);
        
        // 第二阶段：计算最终结果
        y <= partial_sum_0 + partial_sum_1;
    end
endmodule