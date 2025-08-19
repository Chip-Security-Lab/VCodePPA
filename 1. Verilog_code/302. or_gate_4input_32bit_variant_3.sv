//SystemVerilog
module or_gate_4input_32bit #(
    parameter WIDTH = 32
) (
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire [WIDTH-1:0] c,
    input  wire [WIDTH-1:0] d,
    output wire [WIDTH-1:0] y
);
    // 内部连接信号
    wire [WIDTH-1:0] ab_or;
    wire [WIDTH-1:0] cd_or;
    
    // 第一级OR操作
    or_level1 #(
        .WIDTH(WIDTH)
    ) u_or_level1 (
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .ab_result(ab_or),
        .cd_result(cd_or)
    );
    
    // 第二级OR操作
    or_level2 #(
        .WIDTH(WIDTH)
    ) u_or_level2 (
        .ab_result(ab_or),
        .cd_result(cd_or),
        .final_result(y)
    );
endmodule

// 第一级OR操作子模块
module or_level1 #(
    parameter WIDTH = 32
) (
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire [WIDTH-1:0] c,
    input  wire [WIDTH-1:0] d,
    output wire [WIDTH-1:0] ab_result,
    output wire [WIDTH-1:0] cd_result
);
    // 并行计算两组OR结果
    assign ab_result = a | b;
    assign cd_result = c | d;
endmodule

// 第二级OR操作子模块
module or_level2 #(
    parameter WIDTH = 32
) (
    input  wire [WIDTH-1:0] ab_result,
    input  wire [WIDTH-1:0] cd_result,
    output wire [WIDTH-1:0] final_result
);
    // 计算最终的OR结果
    assign final_result = ab_result | cd_result;
endmodule