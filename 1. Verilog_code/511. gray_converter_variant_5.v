module gray_converter_top(
    input [3:0] bin,
    output [3:0] gray
);
    // 实例化MSB处理模块
    gray_msb_handler msb_handler(
        .bin_msb(bin[3]),
        .gray_msb(gray[3])
    );

    // 实例化LSB处理模块
    gray_lsb_handler lsb_handler(
        .bin_in(bin[3:1]),
        .bin_ref(bin[2:0]),
        .gray_lsb(gray[2:0])
    );
endmodule

// MSB处理模块 - 直接传递最高位
module gray_msb_handler(
    input bin_msb,
    output gray_msb
);
    assign gray_msb = bin_msb;
endmodule

// LSB处理模块 - 处理低3位的异或转换
module gray_lsb_handler(
    input [2:0] bin_in,
    input [2:0] bin_ref,
    output [2:0] gray_lsb
);
    assign gray_lsb = bin_in ^ bin_ref;
endmodule