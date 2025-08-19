module ParamOR #(parameter WIDTH=8) (
    input [WIDTH-1:0] in1, in2,
    output [WIDTH-1:0] result
);
    assign result = in1 | in2;  // 可配置位宽
endmodule