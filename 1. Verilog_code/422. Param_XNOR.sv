module Param_XNOR #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_a,
    input [WIDTH-1:0] data_b,
    output [WIDTH-1:0] result
);
    assign result = ~(data_a ^ data_b); // 可配置总线宽度
endmodule
