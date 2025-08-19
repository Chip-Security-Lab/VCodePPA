// 顶层模块
module subtractor_conditional (
    input wire [7:0] a,
    input wire [7:0] b, 
    output wire [7:0] res
);

wire [7:0] diff;
wire borrow;

// 实例化减法运算子模块
subtraction_core u_sub_core (
    .a(a),
    .b(b),
    .diff(diff),
    .borrow(borrow)
);

// 实例化结果选择子模块
result_selector u_result_sel (
    .diff(diff),
    .borrow(borrow),
    .res(res)
);

endmodule

// 减法运算子模块
module subtraction_core (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [7:0] diff,
    output wire borrow
);

assign {borrow, diff} = {1'b0, a} - {1'b0, b};

endmodule

// 结果选择子模块
module result_selector (
    input wire [7:0] diff,
    input wire borrow,
    output wire [7:0] res
);

assign res = borrow ? 8'd0 : diff;

endmodule