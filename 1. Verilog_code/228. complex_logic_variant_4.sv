//SystemVerilog
module bitwise_ops (
    input [3:0] a, b,
    output [3:0] or_result,
    output [3:0] xor_result
);
    assign or_result = a | b;
    assign xor_result = a ^ b;
endmodule

module arithmetic_ops (
    input [3:0] operand1,
    input [3:0] operand2,
    output [3:0] add_result
);
    assign add_result = operand1 + operand2;
endmodule

module complex_logic (
    input [3:0] a, b, c,
    output [3:0] res1,
    output [3:0] res2
);
    wire [3:0] or_result;
    wire [3:0] xor_result;
    
    bitwise_ops u_bitwise (
        .a(a),
        .b(b),
        .or_result(or_result),
        .xor_result(xor_result)
    );
    
    arithmetic_ops u_arithmetic (
        .operand1(xor_result),
        .operand2(c),
        .add_result(res2)
    );
    
    assign res1 = or_result & c;
endmodule