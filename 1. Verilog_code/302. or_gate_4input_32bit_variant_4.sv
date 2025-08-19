//SystemVerilog
// 顶层模块
module or_gate_4input_32bit (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [31:0] c,
    input  wire [31:0] d,
    output wire [31:0] y
);
    // 中间连接信号
    wire [31:0] ab_or;
    wire [31:0] cd_or;
    
    // 子模块实例
    or_gate_2input_32bit u_or_ab (
        .a(a),
        .b(b),
        .y(ab_or)
    );
    
    or_gate_2input_32bit u_or_cd (
        .a(c),
        .b(d),
        .y(cd_or)
    );
    
    or_gate_2input_32bit u_or_final (
        .a(ab_or),
        .b(cd_or),
        .y(y)
    );
endmodule

// 可参数化的2输入或门子模块
module or_gate_2input_32bit #(
    parameter WIDTH = 32
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] y
);
    // 按位或操作
    assign y = a | b;
endmodule