//SystemVerilog
// SystemVerilog
// 优化后的顶层模块 - 进一步简化比较逻辑
module Comparator_BitwiseXOR #(parameter WIDTH = 8) (
    input  [WIDTH-1:0] vec_a,
    input  [WIDTH-1:0] vec_b,
    output             not_equal
);
    // 直接判断两个向量是否不相等，无需中间变量
    assign not_equal = |{vec_a ^ vec_b};
endmodule

// 优化后的Brent-Kung结构
module BrentKung_Differ #(parameter WIDTH = 8) (
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    output [WIDTH-1:0] diff,
    output             cout
);
    // 直接计算异或差异
    assign diff = a ^ b;
    
    // 生成进位信号 - 优化进位链计算
    wire [WIDTH:0] c;
    assign c[0] = 1'b0;
    
    // 简化的生成和传播逻辑 - 直接计算而不使用中间变量
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : GEN_CARRY
            // 使用条件运算符简化进位计算
            assign c[i+1] = (a[i] & b[i]) | ((a[i] ^ b[i]) & c[i]);
        end
    endgenerate
    
    // 最终进位输出
    assign cout = c[WIDTH];
endmodule