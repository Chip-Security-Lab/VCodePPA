module ParamNOT #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);
    assign data_out = ~data_in;  // 参数化位宽取反
endmodule
