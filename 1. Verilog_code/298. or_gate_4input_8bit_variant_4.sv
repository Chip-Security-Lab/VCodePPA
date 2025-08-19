//SystemVerilog
// SystemVerilog
// 顶层模块
module or_gate_4input_8bit (
    input wire [7:0] a,
    input wire [7:0] b,
    input wire [7:0] c,
    input wire [7:0] d,
    output wire [7:0] y
);
    // 第一级OR运算的中间结果
    wire [7:0] ab_result;
    wire [7:0] cd_result;
    
    // 实例化两个2输入OR子模块，处理第一级OR运算
    or_gate_2input_8bit or_ab (
        .a(a),
        .b(b),
        .y(ab_result)
    );
    
    or_gate_2input_8bit or_cd (
        .a(c),
        .b(d),
        .y(cd_result)
    );
    
    // 实例化最终的2输入OR子模块，合并第一级的结果
    or_gate_2input_8bit or_final (
        .a(ab_result),
        .b(cd_result),
        .y(y)
    );
endmodule

// 2输入OR子模块
module or_gate_2input_8bit #(
    parameter WIDTH = 8  // 参数化位宽，提高可复用性
) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] y
);
    // 优化：使用generate块实现按位OR，可能使得某些工具能更好地优化
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_or
            assign y[i] = a[i] | b[i];
        end
    endgenerate
endmodule