module MultiInput_AND #(parameter INPUTS=4) (
    input [INPUTS-1:0] signals,
    output result
);
    assign result = &signals; // 参数化输入数量
endmodule
