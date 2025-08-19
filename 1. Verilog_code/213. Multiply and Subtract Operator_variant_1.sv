//SystemVerilog
// 顶层模块
module signed_multiply_subtract (
    input signed [7:0] a,
    input signed [7:0] b,
    input signed [7:0] c,
    output signed [15:0] result
);
    // 内部连线
    wire signed [15:0] multiply_result;
    
    // 实例化乘法子模块
    signed_multiplier mult_unit (
        .multiplicand(a),
        .multiplier(b),
        .product(multiply_result)
    );
    
    // 实例化减法子模块
    signed_subtractor sub_unit (
        .minuend(multiply_result),
        .subtrahend({{8{c[7]}}, c}), // 符号扩展
        .difference(result)
    );
endmodule

// 乘法子模块
module signed_multiplier #(
    parameter INPUT_WIDTH = 8,
    parameter OUTPUT_WIDTH = 16
) (
    input signed [INPUT_WIDTH-1:0] multiplicand,
    input signed [INPUT_WIDTH-1:0] multiplier,
    output signed [OUTPUT_WIDTH-1:0] product
);
    // 乘法实现
    assign product = multiplicand * multiplier;
endmodule

// 减法子模块
module signed_subtractor #(
    parameter WIDTH = 16
) (
    input signed [WIDTH-1:0] minuend,
    input signed [WIDTH-1:0] subtrahend,
    output signed [WIDTH-1:0] difference
);
    // 减法实现
    assign product = minuend - subtrahend;
endmodule