//SystemVerilog
// SystemVerilog
// 异步组合逻辑比较器，带参数化位宽
module Comparator_BaseAsync #(parameter WIDTH = 8) (
    input  [WIDTH-1:0] data_a,    // 输入数据A
    input  [WIDTH-1:0] data_b,    // 输入数据B
    output reg         o_equal    // 等于比较结果
);
    reg [WIDTH-1:0] diff;         // 差值
    reg carry;                    // 进位标志
    integer i;                    // 循环变量
    
    always @(*) begin
        diff = 0;
        carry = 0;
        
        // 条件求和减法算法实现 - 使用while循环
        i = 0;                    // 初始化放在循环前
        while (i < WIDTH) begin
            diff[i] = data_a[i] ^ data_b[i] ^ carry;
            carry = (~data_a[i] & data_b[i]) | (~data_a[i] & carry) | (data_b[i] & carry);
            i = i + 1;            // 迭代步骤放在循环体末尾
        end
        
        // 如果差值为0，则两数相等
        o_equal = (diff == 0);
    end
endmodule