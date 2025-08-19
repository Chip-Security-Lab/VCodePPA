module parity_generator #(
    parameter DATA_WIDTH = 8,
    parameter EVEN_PARITY = 1  // 1为偶校验，0为奇校验
)(
    input [DATA_WIDTH-1:0] data,
    output parity_bit
);
    wire raw_parity;
    assign raw_parity = ^data;  // 使用XOR归约操作符计算奇偶性
    assign parity_bit = EVEN_PARITY ? raw_parity : ~raw_parity;
endmodule