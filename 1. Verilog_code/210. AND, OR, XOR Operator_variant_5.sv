//SystemVerilog
module and_or_xor_operator (
    input [7:0] a,
    input [7:0] b,
    output [7:0] and_result,
    output [7:0] or_result,
    output [7:0] xor_result
);
    // 实例化与运算子模块
    and_operator and_op (
        .a_in(a),
        .b_in(b),
        .result(and_result)
    );
    
    // 实例化或运算子模块
    or_operator or_op (
        .a_in(a),
        .b_in(b),
        .result(or_result)
    );
    
    // 实例化异或运算子模块
    xor_operator xor_op (
        .a_in(a),
        .b_in(b),
        .result(xor_result)
    );
    
endmodule

// 与运算子模块
module and_operator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a_in,
    input [WIDTH-1:0] b_in,
    output [WIDTH-1:0] result
);
    assign result = a_in & b_in;
endmodule

// 或运算子模块
module or_operator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a_in,
    input [WIDTH-1:0] b_in,
    output [WIDTH-1:0] result
);
    assign result = a_in | b_in;
endmodule

// 异或运算子模块
module xor_operator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a_in,
    input [WIDTH-1:0] b_in,
    output [WIDTH-1:0] result
);
    assign result = a_in ^ b_in;
endmodule