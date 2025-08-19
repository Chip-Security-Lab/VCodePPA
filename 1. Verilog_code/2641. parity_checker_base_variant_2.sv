//SystemVerilog
// 顶层模块
module parity_checker_top (
    input [7:0] data_in,
    output parity_bit
);

    // 实例化奇校验子模块
    parity_checker u_parity_checker (
        .data_in(data_in),
        .parity_bit(parity_bit)
    );

endmodule

// 奇校验子模块
module parity_checker (
    input [7:0] data_in,
    output parity_bit
);

    // 计算奇校验位
    assign parity_bit = ^data_in; // 奇校验：1的个数为奇数时输出1

endmodule