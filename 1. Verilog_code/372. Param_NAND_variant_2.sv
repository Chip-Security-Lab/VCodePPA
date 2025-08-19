//SystemVerilog
module Param_NAND #(parameter WIDTH=8) (
    input [WIDTH-1:0] x, y,
    output reg [WIDTH-1:0] z
);
    // 使用条件反相减法器算法实现NAND功能
    reg [WIDTH:0] op_a, op_b;
    reg [WIDTH:0] result;
    reg invert;
    
    always @(*) begin
        // NAND(x,y) = ~(x & y) 可以通过条件反相减法实现
        // 我们使用减法运算 a - b 的特性，当结果为0表示a=b
        // 对于NAND，我们检测x&y是否为0，然后反转结果
        
        op_a = {1'b0, x};
        op_b = {1'b0, y & x}; // 计算x&y
        invert = 1'b1; // 我们需要反转结果
        
        // 条件反相减法器实现
        if (invert) begin
            op_b = ~op_b + 1'b1; // 如果需要反相，对b进行二进制补码
        end
        
        result = op_a + op_b; // 执行加法(当op_b被补码时，实际上是减法)
        
        // 最终结果: 如果x&y为0，result非0；如果x&y非0，result为0
        // 由于NAND要求x&y为0时输出1，x&y非0时输出0
        // 我们检测result是否为0，并据此设置输出
        if (result[WIDTH-1:0] == {WIDTH{1'b0}}) begin
            z = {WIDTH{1'b0}}; // x&y非0时，输出全0
        end else begin
            z = {WIDTH{1'b1}}; // x&y为0时，输出全1
        end
    end
endmodule