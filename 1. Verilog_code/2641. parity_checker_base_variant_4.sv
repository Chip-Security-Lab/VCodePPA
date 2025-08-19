//SystemVerilog
// 顶层模块
module parity_checker_top (
    input [7:0] data_in,
    output parity_bit
);

// 实例化子模块
wire parity_result;

parity_calculator u_parity_calculator (
    .data_in(data_in),
    .parity_out(parity_result)
);

// 将子模块的输出连接到顶层模块的输出
assign parity_bit = parity_result;

endmodule

// 子模块：奇校验计算器
module parity_calculator (
    input [7:0] data_in,
    output parity_out
);

// 计算奇校验
assign parity_out = ^data_in; // 奇校验：1的个数为奇数时输出1

endmodule