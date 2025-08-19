// 顶层模块
module gray_converter_top(
    input [3:0] bin,
    output [3:0] gray
);

    // 内部信号
    wire [2:0] xor_result;
    
    // 实例化格雷码转换子模块
    gray_converter_core gray_core_inst(
        .bin(bin),
        .xor_result(xor_result)
    );
    
    // 实例化输出组合子模块
    gray_converter_output output_inst(
        .bin(bin),
        .xor_result(xor_result),
        .gray(gray)
    );

endmodule

// 格雷码转换核心子模块
module gray_converter_core(
    input [3:0] bin,
    output [2:0] xor_result
);
    // 计算异或结果
    assign xor_result = bin[3:1] ^ bin[2:0];
endmodule

// 输出组合子模块
module gray_converter_output(
    input [3:0] bin,
    input [2:0] xor_result,
    output [3:0] gray
);
    // 组合最终输出
    assign gray = {bin[3], xor_result};
endmodule