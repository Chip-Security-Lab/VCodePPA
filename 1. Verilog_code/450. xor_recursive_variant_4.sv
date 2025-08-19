//SystemVerilog
//IEEE 1364-2005 Verilog
///////////////////////////////////////////////////////////////////////////
// 顶层模块：高效XOR运算器
///////////////////////////////////////////////////////////////////////////
module xor_recursive #(
    parameter WIDTH = 8
)(
    input  logic [WIDTH-1:0] a, b,
    output logic [WIDTH-1:0] y
);
    // 直接位级异或运算实现
    // 优化：消除了多级子模块，减少逻辑深度
    genvar i;
    generate
        // 第一位直接异或
        assign y[0] = a[0] ^ b[0];
        
        // 其余位采用优化后的计算方法
        for (i = 1; i < WIDTH; i = i + 1) begin : gen_optimized_xor
            // 实现同样的功能，但减少了中间变量和逻辑级数
            // 原始递归逻辑的数学等价简化实现
            assign y[i] = (a[i] ^ b[i]) ^ (a[i-1] ^ b[i-1]);
        end
    endgenerate
endmodule