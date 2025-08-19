module FIR #(parameter W=8) (
    input clk, 
    input [W-1:0] sample,
    output reg [W+3:0] y
);
    // 定义系数作为单独参数
    parameter [3:0] COEFFS = 4'hA;
    
    reg [W-1:0] delay_line [0:3];
    integer i;
    
    always @(posedge clk) begin
        // 手动移位延迟线
        for(i=3; i>0; i=i-1)
            delay_line[i] <= delay_line[i-1];
        delay_line[0] <= sample;
        
        // 计算输出
        y <= (delay_line[3] * COEFFS[3]) + 
             (delay_line[2] * COEFFS[2]) +
             (delay_line[1] * COEFFS[1]) + 
             (delay_line[0] * COEFFS[0]);
    end
endmodule