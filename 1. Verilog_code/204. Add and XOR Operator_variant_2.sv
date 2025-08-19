//SystemVerilog
// 顶层模块
module multiply_divide_operator (
    input  [7:0]  a,
    input  [7:0]  b,
    output [15:0] product,
    output [7:0]  quotient,
    output [7:0]  remainder
);
    // 实例化乘法子模块
    karatsuba_multiplier mult_inst (
        .multiplicand(a),
        .multiplier(b),
        .product(product)
    );
    
    // 实例化除法子模块
    divider div_inst (
        .dividend(a),
        .divisor(b),
        .quotient(quotient),
        .remainder(remainder)
    );
endmodule

// 基拉斯基乘法器子模块
module karatsuba_multiplier #(
    parameter WIDTH_A = 8,
    parameter WIDTH_B = 8,
    parameter WIDTH_P = 16
)(
    input  [WIDTH_A-1:0] multiplicand,
    input  [WIDTH_B-1:0] multiplier,
    output [WIDTH_P-1:0] product
);
    // 基拉斯基乘法器实现
    reg [WIDTH_P-1:0] product_reg;
    
    // 中间变量
    reg [WIDTH_A/2-1:0] a_high, a_low;
    reg [WIDTH_B/2-1:0] b_high, b_low;
    reg [WIDTH_A/2:0] a_sum;
    reg [WIDTH_B/2:0] b_sum;
    reg [WIDTH_A/2+WIDTH_B/2:0] sum_prod;
    reg [WIDTH_A/2+WIDTH_B/2:0] high_prod;
    reg [WIDTH_A/2+WIDTH_B/2:0] low_prod;
    
    always @(*) begin
        // 分解操作数
        a_high = multiplicand[WIDTH_A-1:WIDTH_A/2];
        a_low = multiplicand[WIDTH_A/2-1:0];
        b_high = multiplier[WIDTH_B-1:WIDTH_B/2];
        b_low = multiplier[WIDTH_B/2-1:0];
        
        // 计算和
        a_sum = a_high + a_low;
        b_sum = b_high + b_low;
        
        // 计算三个部分积
        high_prod = a_high * b_high;
        low_prod = a_low * b_low;
        sum_prod = a_sum * b_sum;
        
        // 组合结果
        product_reg = (high_prod << WIDTH_A) + 
                      ((sum_prod - high_prod - low_prod) << (WIDTH_A/2)) + 
                      low_prod;
    end
    
    assign product = product_reg;
endmodule

// 除法和余数子模块
module divider #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] dividend,
    input  [WIDTH-1:0] divisor,
    output [WIDTH-1:0] quotient,
    output [WIDTH-1:0] remainder
);
    // 防止除零错误的逻辑
    wire [WIDTH-1:0] safe_divisor;
    assign safe_divisor = (divisor == 0) ? 1'b1 : divisor;
    
    // 计算结果
    assign quotient = dividend / safe_divisor;
    assign remainder = dividend % safe_divisor;
endmodule