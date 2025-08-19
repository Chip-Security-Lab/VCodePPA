//SystemVerilog
// Top-level module
module or_gate_3input_16bit (
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire [15:0] c,
    output wire [15:0] y
);
    // 内部连线
    wire [15:0] ab_or;
    
    // 实例化两个子模块
    or_gate_2input_16bit u_or_ab (
        .a(a),
        .b(b),
        .y(ab_or)
    );
    
    or_gate_2input_16bit u_or_final (
        .a(ab_or),
        .b(c),
        .y(y)
    );
endmodule

// 2输入16位OR门子模块
module or_gate_2input_16bit #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] y
);
    // 将WIDTH参数化，提高可复用性
    // 实现基本的2输入OR功能
    assign y = a | b;
endmodule