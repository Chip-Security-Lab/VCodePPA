module DebugNOT(
    input [7:0] data,
    output [7:0] inverse,
    output parity  // 调试信号
);
    assign inverse = ~data;
    assign parity = ^inverse;  // 附加奇偶校验
endmodule
