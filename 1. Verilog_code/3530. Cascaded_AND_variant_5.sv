//SystemVerilog
module Cascaded_AND(
    input wire [2:0] in,
    output reg out
);
    // 使用带符号乘法实现AND逻辑
    // 对于位宽为3的操作数，我们可以将AND操作转换为乘法操作
    // 如果所有输入位都为1，则输出为1，否则为0
    
    reg signed [1:0] input_product;
    
    always @(*) begin
        // 使用带符号乘法实现AND逻辑
        // 将输入位归一化为+1/-1表示，然后计算乘积
        // 如果所有位都为1，则乘积为1；否则为0
        input_product = (in[0] ? 1 : -1) * (in[1] ? 1 : -1) * (in[2] ? 1 : -1);
        
        // 如果乘积为1，则所有输入都是1
        out = (input_product == 1) ? 1'b1 : 1'b0;
    end
endmodule