module bitwise_transform(
    input [3:0] in,
    output [3:0] out
);
    assign out = {in[0], in[1], in[2], in[3]};  // 位重排序
endmodule