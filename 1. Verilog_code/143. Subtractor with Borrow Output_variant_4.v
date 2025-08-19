module subtractor_with_cout (
    input wire [3:0] minuend,
    input wire [3:0] subtrahend,
    output wire [3:0] difference,
    output wire cout
);

// 实例化4位先行借位减法器
lookahead_subtractor_4bit u_lookahead_subtractor (
    .minuend(minuend),
    .subtrahend(subtrahend),
    .difference(difference),
    .cout(cout)
);

endmodule

// 4位先行借位减法器模块
module lookahead_subtractor_4bit (
    input wire [3:0] minuend,
    input wire [3:0] subtrahend,
    output wire [3:0] difference,
    output wire cout
);

wire [3:0] b_not;
wire [3:0] g;
wire [3:0] p;
wire [3:0] borrow;

// 生成和传播信号
assign b_not = ~subtrahend;
assign g = minuend & b_not;
assign p = minuend ^ b_not;

// 先行借位计算
assign borrow[0] = 1'b0;
assign borrow[1] = g[0] | (p[0] & borrow[0]);
assign borrow[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & borrow[0]);
assign borrow[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & borrow[0]);

// 计算差值
assign difference = p ^ borrow;

// 输出借位
assign cout = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & borrow[0]);

endmodule