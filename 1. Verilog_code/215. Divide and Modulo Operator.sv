module add_xor_not_operator (
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum,
    output [7:0] xor_not_result
);
    assign sum = a + b;                // 加法
    assign xor_not_result = ~(a ^ b);   // 异或非
endmodule
