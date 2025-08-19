//SystemVerilog
module FIR #(parameter W=8) (
    input clk, 
    input [W-1:0] sample,
    output [W+3:0] y
);
    // 定义系数作为单独参数
    parameter [3:0] COEFFS = 4'hA;
    
    reg [W-1:0] delay_line [0:3];
    // 对每个乘法结果进行单独寄存
    reg [W+3:0] mult_results [0:3];
    wire [W+3:0] y_wire;
    integer i;
    
    always @(posedge clk) begin
        // 手动移位延迟线
        for(i=3; i>0; i=i-1)
            delay_line[i] <= delay_line[i-1];
        delay_line[0] <= sample;
        
        // 将乘法结果寄存起来
        mult_results[0] <= delay_line[0] * COEFFS[0];
        mult_results[1] <= delay_line[1] * COEFFS[1];
        mult_results[2] <= delay_line[2] * COEFFS[2];
        mult_results[3] <= delay_line[3] * COEFFS[3];
    end
    
    // 组合逻辑加法运算
    assign y_wire = mult_results[0] + mult_results[1] + 
                    mult_results[2] + mult_results[3];
    
    // 最终输出
    assign y = y_wire;
endmodule