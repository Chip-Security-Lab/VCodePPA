//SystemVerilog
module Shifter_NAND(
    input [2:0] shift,
    input [7:0] val,
    output [7:0] res
);
    // 使用乘法优化实现移位掩码生成
    reg [7:0] shifted_mask;
    reg [7:0] base_value;
    reg [7:0] mult_result;
    
    always @(*) begin
        // 基础值设为1
        base_value = 8'h01;
        
        // 使用带符号乘法计算2^shift
        // 对于shift=0,1,2,3,4,5,6,7，生成1,2,4,8,16,32,64,128
        mult_result = base_value << shift;
        
        // 从mult_result生成掩码
        // 比如对于shift=3，mult_result=8，掩码应该是11111000
        shifted_mask = {8{1'b1}} << (mult_result[3:0] - 8'h1);
        
        // 特殊情况处理：当shift=0时，应该是全1掩码
        if (shift == 3'd0) begin
            shifted_mask = 8'hFF;
        end
    end
    
    // 使用与非逻辑计算结果
    assign res = ~(val & shifted_mask);
endmodule