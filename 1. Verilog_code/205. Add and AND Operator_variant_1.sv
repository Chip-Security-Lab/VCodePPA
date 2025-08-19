//SystemVerilog
// 加法子模块
module adder_submodule #(
    parameter WIDTH = 8
) (
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    output [WIDTH-1:0] sum
);
    assign sum = a + b;
endmodule

// 与操作子模块
module and_submodule #(
    parameter WIDTH = 8
) (
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    output [WIDTH-1:0] and_result
);
    assign and_result = a & b;
endmodule

// 数据通路控制子模块
module datapath_control #(
    parameter WIDTH = 8
) (
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    output [WIDTH-1:0] sum,
    output [WIDTH-1:0] and_result
);
    // 实例化加法子模块
    adder_submodule #(WIDTH) adder_inst (
        .a(a),
        .b(b),
        .sum(sum)
    );
    
    // 实例化与操作子模块
    and_submodule #(WIDTH) and_inst (
        .a(a),
        .b(b),
        .and_result(and_result)
    );
endmodule

// 顶层模块
module add_and_operator #(
    parameter WIDTH = 8
) (
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    output [WIDTH-1:0] sum,
    output [WIDTH-1:0] and_result
);
    // 实例化数据通路控制模块
    datapath_control #(WIDTH) datapath_inst (
        .a(a),
        .b(b),
        .sum(sum),
        .and_result(and_result)
    );
endmodule