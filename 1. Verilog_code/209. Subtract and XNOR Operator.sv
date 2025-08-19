module subtract_xnor_operator (
    input [7:0] a,
    input [7:0] b,
    output [7:0] difference,
    output [7:0] xnor_result
);
    assign difference = a - b;      // 减法
    assign xnor_result = ~(a ^ b);  // 异或非
endmodule
