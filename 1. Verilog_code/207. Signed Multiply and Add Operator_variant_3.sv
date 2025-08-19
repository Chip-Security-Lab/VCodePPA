//SystemVerilog
// 顶层模块
module signed_multiply_add (
    input signed [7:0] a,
    input signed [7:0] b,
    input signed [7:0] c,
    output signed [15:0] result
);
    wire signed [15:0] mult_result;
    
    // 实例化乘法子模块
    signed_multiplier mult_unit (
        .multiplicand(a),
        .multiplier(b),
        .product(mult_result)
    );
    
    // 实例化加法子模块
    signed_adder add_unit (
        .addend_a(mult_result),
        .addend_b({{8{c[7]}}, c}), // 符号扩展
        .sum(result)
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
    // 优化的乘法实现
    reg signed [OUTPUT_WIDTH-1:0] product_reg;
    
    always @(*) begin
        product_reg = multiplicand * multiplier;
    end
    
    assign product = product_reg;
endmodule

// 加法子模块
module signed_adder #(
    parameter WIDTH = 16
) (
    input signed [WIDTH-1:0] addend_a,
    input signed [WIDTH-1:0] addend_b, 
    output signed [WIDTH-1:0] sum
);
    // 带快进位的加法器实现
    reg signed [WIDTH-1:0] sum_reg;
    
    always @(*) begin
        sum_reg = addend_a + addend_b;
    end
    
    assign sum = sum_reg;
endmodule