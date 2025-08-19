// 顶层模块
module subtractor_8bit_negative (
    input [7:0] a,
    input [7:0] b, 
    output [7:0] diff
);

    // 内部信号
    wire [7:0] neg_b;
    wire [7:0] sum;
    wire carry;

    // 实例化取反模块
    negator_8bit negator_inst (
        .in(b),
        .out(neg_b)
    );

    // 实例化加法器模块
    adder_8bit adder_inst (
        .a(a),
        .b(neg_b),
        .sum(sum),
        .carry(carry)
    );

    // 实例化结果处理模块
    result_processor result_inst (
        .sum(sum),
        .carry(carry),
        .diff(diff)
    );

endmodule

// 8位取反模块
module negator_8bit (
    input [7:0] in,
    output [7:0] out
);
    // 取反加1实现负数
    assign out = ~in + 1'b1;
endmodule

// 8位加法器模块
module adder_8bit (
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum,
    output carry
);
    // 带进位的加法实现
    assign {carry, sum} = a + b;
endmodule

// 结果处理模块
module result_processor (
    input [7:0] sum,
    input carry,
    output [7:0] diff
);
    // 处理加法结果
    assign diff = sum;
endmodule