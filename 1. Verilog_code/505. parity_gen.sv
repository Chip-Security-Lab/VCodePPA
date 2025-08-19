module parity_gen(
    input [7:0] data,
    output parity
);
    assign parity = ^data;  // 异或树实现
endmodule