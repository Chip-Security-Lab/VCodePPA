// 顶层模块
module ora_and_inv_top(
    input wire a,
    input wire b,
    input wire c,
    output wire y
);

    // 内部信号定义
    wire nor_out;
    wire and_out;
    wire inv_out;

    // 实例化NOR子模块
    nor_module nor_inst(
        .a(a),
        .b(b),
        .out(nor_out)
    );

    // 实例化AND子模块
    and_module and_inst(
        .a(nor_out),
        .b(c),
        .out(and_out)
    );

    // 实例化INV子模块
    inv_module inv_inst(
        .a(and_out),
        .out(y)
    );

endmodule

// NOR子模块
module nor_module(
    input wire a,
    input wire b,
    output wire out
);
    assign out = ~(a | b);
endmodule

// AND子模块
module and_module(
    input wire a,
    input wire b,
    output wire out
);
    assign out = a & b;
endmodule

// INV子模块
module inv_module(
    input wire a,
    output wire out
);
    assign out = ~a;
endmodule