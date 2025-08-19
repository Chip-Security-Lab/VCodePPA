//SystemVerilog
module Comparator_BaseAsync #(parameter WIDTH = 8) (
    input  [WIDTH-1:0] data_a,    // 输入数据A
    input  [WIDTH-1:0] data_b,    // 输入数据B
    output reg         o_equal    // 等于比较结果
);
    // 使用条件求和减法算法实现减法
    wire [WIDTH:0] borrow;        // 借位信号，多一位以处理初始条件
    wire [WIDTH-1:0] diff;        // 差值结果
    
    // 初始无借位
    assign borrow[0] = 1'b0;
    
    // 按位计算差值和借位
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_subtractor
            // 差值计算: diff[i] = a[i] ⊕ b[i] ⊕ borrow[i]
            assign diff[i] = data_a[i] ^ data_b[i] ^ borrow[i];
            
            // 借位计算: borrow[i+1] = (~a[i] & b[i]) | (~a[i] & borrow[i]) | (b[i] & borrow[i])
            assign borrow[i+1] = (~data_a[i] & data_b[i]) | (~data_a[i] & borrow[i]) | (data_b[i] & borrow[i]);
        end
    endgenerate
    
    // 如果差值为0，则两数相等
    always @(*) begin
        o_equal = (diff == {WIDTH{1'b0}});
    end
endmodule