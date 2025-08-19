module param_adder #(parameter WIDTH=4) (
    input [WIDTH-1:0] a, b,
    output [WIDTH:0] sum  // 包含进位位
);
    assign sum = a + b;
endmodule