// 顶层模块
module subtractor_4bit (
    input [3:0] a,
    input [3:0] b, 
    output [3:0] diff
);

    // 内部信号
    wire [3:0] b_comp;    // 2's complement of b
    wire [3:0] sum;       // 加法结果
    wire carry_out;       // 进位输出

    // 实例化2's complement模块
    twos_complement_4bit comp_inst (
        .in(b),
        .out(b_comp)
    );

    // 实例化加法器模块
    adder_4bit add_inst (
        .a(a),
        .b(b_comp),
        .sum(sum),
        .carry_out(carry_out)
    );

    // 输出赋值
    assign diff = sum;

endmodule

// 2's complement模块
module twos_complement_4bit (
    input [3:0] in,
    output [3:0] out
);
    assign out = ~in + 1'b1;
endmodule

// 4位加法器模块
module adder_4bit (
    input [3:0] a,
    input [3:0] b,
    output [3:0] sum,
    output carry_out
);
    wire [3:0] carry;
    
    // 最低位加法
    full_adder fa0 (
        .a(a[0]),
        .b(b[0]),
        .cin(1'b0),
        .sum(sum[0]),
        .cout(carry[0])
    );

    // 中间位加法
    full_adder fa1 (
        .a(a[1]),
        .b(b[1]),
        .cin(carry[0]),
        .sum(sum[1]),
        .cout(carry[1])
    );

    full_adder fa2 (
        .a(a[2]),
        .b(b[2]),
        .cin(carry[1]),
        .sum(sum[2]),
        .cout(carry[2])
    );

    // 最高位加法
    full_adder fa3 (
        .a(a[3]),
        .b(b[3]),
        .cin(carry[2]),
        .sum(sum[3]),
        .cout(carry_out)
    );

endmodule

// 全加器模块
module full_adder (
    input a,
    input b,
    input cin,
    output sum,
    output cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));
endmodule