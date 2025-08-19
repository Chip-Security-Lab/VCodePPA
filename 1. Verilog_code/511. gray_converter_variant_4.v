module gray_converter_top(
    input [3:0] bin,
    output [3:0] gray
);
    // 实例化子模块
    gray_converter_core u_gray_core(
        .bin(bin),
        .gray(gray)
    );
endmodule

module gray_converter_core(
    input [3:0] bin,
    output [3:0] gray
);
    // 使用位拼接和移位操作优化异或链
    assign gray = bin ^ {1'b0, bin[3:1]};
endmodule