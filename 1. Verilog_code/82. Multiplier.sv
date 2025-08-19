module Multiplier2#(parameter WIDTH=4)(
    input [WIDTH-1:0] x, y,
    output [2*WIDTH-1:0] product
);
    assign product = x * y;  // 参数化设计
endmodule