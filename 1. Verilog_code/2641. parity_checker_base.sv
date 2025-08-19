module parity_checker_base (
    input [7:0] data_in,
    output parity_bit
);
assign parity_bit = ^data_in; // 奇校验：1的个数为奇数时输出1
endmodule