module and_or_xor_operator (
    input [7:0] a,
    input [7:0] b,
    output [7:0] and_result,
    output [7:0] or_result,
    output [7:0] xor_result
);
    assign and_result = a & b;      // 与操作
    assign or_result = a | b;       // 或操作
    assign xor_result = a ^ b;      // 异或
endmodule


