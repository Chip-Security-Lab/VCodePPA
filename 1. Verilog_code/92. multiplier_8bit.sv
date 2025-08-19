module multiplier_8bit (
    input [7:0] a,
    input [7:0] b,
    output [15:0] product
);
    assign product = a * b;  // 简单的位宽8的乘法器
endmodule
