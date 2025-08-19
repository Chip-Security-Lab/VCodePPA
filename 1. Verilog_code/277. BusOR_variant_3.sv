//SystemVerilog
// 顶层模块：16位总线按位或运算，分层结构
module BusOrTop (
    input  [15:0] bus_a,
    input  [15:0] bus_b,
    output [15:0] bus_or
);

    // 低字节和高字节的或运算结果
    wire [7:0] or_result_low;
    wire [7:0] or_result_high;

    // 实例化低字节或运算单元
    BusOrByte or_byte_low (
        .byte_a  (bus_a[7:0]),
        .byte_b  (bus_b[7:0]),
        .byte_or (or_result_low)
    );

    // 实例化高字节或运算单元
    BusOrByte or_byte_high (
        .byte_a  (bus_a[15:8]),
        .byte_b  (bus_b[15:8]),
        .byte_or (or_result_high)
    );

    // 合成最终16位输出
    BusOrCombine combine_result (
        .or_high (or_result_high),
        .or_low  (or_result_low),
        .bus_or  (bus_or)
    );

endmodule

// 子模块：8位按位或运算
// 功能：对两个8位输入信号进行逐位或操作
module BusOrByte (
    input  [7:0] byte_a,
    input  [7:0] byte_b,
    output [7:0] byte_or
);
    assign byte_or = byte_a | byte_b;
endmodule

// 子模块：16位总线输出组合
// 功能：将两个8位输入拼接为16位输出，便于结构化管理
module BusOrCombine (
    input  [7:0] or_high,
    input  [7:0] or_low,
    output [15:0] bus_or
);
    assign bus_or = {or_high, or_low};
endmodule