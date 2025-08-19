module ConditionalNOT(
    input [31:0] data,
    output [31:0] result
);
    assign result = (data == 32'hFFFFFFFF) ? 0 : ~data;  // 特殊条件处理
endmodule
