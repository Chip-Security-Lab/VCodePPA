//SystemVerilog
// 顶层模块，实例化各个功能子模块
module and_or_xor_operator (
    input [7:0] a,
    input [7:0] b,
    output [7:0] and_result,
    output [7:0] or_result,
    output [7:0] xor_result,
    output [7:0] sub_result
);
    // 实例化与操作子模块
    bitwise_and u_bitwise_and (
        .operand_a(a),
        .operand_b(b),
        .result(and_result)
    );
    
    // 实例化或操作子模块
    bitwise_or u_bitwise_or (
        .operand_a(a),
        .operand_b(b),
        .result(or_result)
    );
    
    // 实例化异或操作子模块
    bitwise_xor u_bitwise_xor (
        .operand_a(a),
        .operand_b(b),
        .result(xor_result)
    );
    
    // 实例化条件求和减法器子模块
    conditional_sum_subtractor u_subtractor (
        .minuend(a),
        .subtrahend(b),
        .difference(sub_result)
    );
endmodule

// 与操作子模块
module bitwise_and #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] operand_a,
    input [WIDTH-1:0] operand_b,
    output [WIDTH-1:0] result
);
    assign result = operand_a & operand_b;
endmodule

// 或操作子模块
module bitwise_or #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] operand_a,
    input [WIDTH-1:0] operand_b,
    output [WIDTH-1:0] result
);
    assign result = operand_a | operand_b;
endmodule

// 异或操作子模块
module bitwise_xor #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] operand_a,
    input [WIDTH-1:0] operand_b,
    output [WIDTH-1:0] result
);
    assign result = operand_a ^ operand_b;
endmodule

// 条件求和减法器子模块
module conditional_sum_subtractor #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] minuend,
    input [WIDTH-1:0] subtrahend,
    output [WIDTH-1:0] difference
);
    wire [WIDTH-1:0] not_subtrahend;
    wire [WIDTH:0] carries;
    
    // 对被减数取反
    assign not_subtrahend = ~subtrahend;
    
    // 初始进位为1（补码表示）
    assign carries[0] = 1'b1;
    
    // 条件求和减法实现
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_sub
            assign difference[i] = minuend[i] ^ not_subtrahend[i] ^ carries[i];
            assign carries[i+1] = (minuend[i] & not_subtrahend[i]) | 
                                  (minuend[i] & carries[i]) | 
                                  (not_subtrahend[i] & carries[i]);
        end
    endgenerate
endmodule