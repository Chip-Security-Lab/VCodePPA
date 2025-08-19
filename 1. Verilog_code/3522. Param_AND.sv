module Param_AND #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_a,
    input [WIDTH-1:0] data_b,
    output [WIDTH-1:0] result
);
    assign result = data_a & data_b; // 可配置位宽与门
endmodule
