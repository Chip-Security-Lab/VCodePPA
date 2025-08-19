//SystemVerilog
// 顶层模块
module signed_add_divide (
    input signed [7:0] a,
    input signed [7:0] b,
    output signed [7:0] sum,
    output signed [7:0] quotient
);
    // 实例化加法子模块
    signed_adder adder_inst (
        .a(a),
        .b(b),
        .result(sum)
    );
    
    // 实例化除法子模块
    signed_divider divider_inst (
        .dividend(a),
        .divisor(b),
        .result(quotient)
    );
endmodule

// 带状进位的加法子模块
module signed_adder #(
    parameter WIDTH = 8
)(
    input signed [WIDTH-1:0] a,
    input signed [WIDTH-1:0] b,
    output signed [WIDTH-1:0] result
);
    // 带状进位加法器实现
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] p, g;
    
    // 生成传播(propagate)和生成(generate)信号
    assign p = a ^ b;
    assign g = a & b;
    
    // 计算进位
    assign carry[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : carry_gen
            assign carry[i+1] = g[i] | (p[i] & carry[i]);
        end
    endgenerate
    
    // 计算结果
    assign result = p ^ carry[WIDTH-1:0];
endmodule

// 除法子模块
module signed_divider #(
    parameter WIDTH = 8
)(
    input signed [WIDTH-1:0] dividend,
    input signed [WIDTH-1:0] divisor,
    output reg signed [WIDTH-1:0] result
);
    // 有符号除法运算 - 使用显式多路复用器结构替代三元运算符
    // 使用always块和case语句实现条件选择，改善综合结果
    wire divisor_is_zero;
    assign divisor_is_zero = (divisor == 0);
    
    wire signed [WIDTH-1:0] division_result;
    assign division_result = dividend / divisor;
    
    // 使用多路复用器模式实现条件选择
    always @(*) begin
        case (divisor_is_zero)
            1'b1: result = {WIDTH{1'b1}}; // 除零情况，全部置为1
            1'b0: result = division_result; // 正常除法结果
        endcase
    end
endmodule