module Param_NAND #(parameter WIDTH=8) (
    input [WIDTH-1:0] x, y,
    output [WIDTH-1:0] z
);
    assign z = ~(x & y);  // 可配置总线宽度
endmodule
