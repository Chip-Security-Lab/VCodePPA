//SystemVerilog
// SystemVerilog
// 顶层模块
module or_gate_3input_8bit (
    input wire [7:0] a,
    input wire [7:0] b,
    input wire [7:0] c,
    output wire [7:0] y
);
    // 内部连线
    wire [7:0] ab_result;
    
    // 实例化第一级或运算子模块 (a 与 b)
    or_gate_2input_8bit u_or_ab (
        .a(a),
        .b(b),
        .y(ab_result)
    );
    
    // 实例化第二级或运算子模块 (ab_result 与 c)
    or_gate_2input_8bit u_or_abc (
        .a(ab_result),
        .b(c),
        .y(y)
    );
endmodule

// 2输入8位或门子模块
module or_gate_2input_8bit #(
    parameter WIDTH = 8  // 参数化位宽，提高可复用性
) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] y
);
    // 采用生成块按位实现或运算，允许更好的布局优化
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_or_bits
            assign y[i] = a[i] | b[i];
        end
    endgenerate
endmodule