//SystemVerilog
// 顶层模块
module multi_route_xnor2 (
    input  wire [7:0] input1, input2, input3,
    output wire [7:0] output_xnor
);
    // 内部连线
    wire [7:0] xnor_result1;
    wire [7:0] xnor_result2;
    wire [7:0] subtraction_result;
    
    // 子模块实例化
    xnor_operation #(
        .WIDTH(8)
    ) xnor_op1 (
        .a(input1),
        .b(input2),
        .result(xnor_result1)
    );
    
    xnor_operation #(
        .WIDTH(8)
    ) xnor_op2 (
        .a(input2),
        .b(input3),
        .result(xnor_result2)
    );
    
    // 先行借位减法器
    look_ahead_subtractor #(
        .WIDTH(8)
    ) sub_op (
        .minuend(xnor_result1),
        .subtrahend(input3),
        .difference(subtraction_result)
    );
    
    bitwise_and #(
        .WIDTH(8)
    ) and_op (
        .a(xnor_result2),
        .b(subtraction_result),
        .result(output_xnor)
    );
    
endmodule

// 先行借位减法器子模块
module look_ahead_subtractor #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] minuend,      // 被减数
    input  wire [WIDTH-1:0] subtrahend,   // 减数
    output wire [WIDTH-1:0] difference    // 差
);
    wire [WIDTH:0] borrow;       // 借位信号，需要额外一位
    wire [WIDTH-1:0] p;          // 传播信号
    wire [WIDTH-1:0] g;          // 生成信号
    wire [WIDTH-1:0] sub_xor;    // XOR结果
    
    // 初始无借位
    assign borrow[0] = 1'b0;
    
    // 计算生成和传播信号
    assign p = ~minuend;         // 传播借位条件
    assign g = ~minuend & subtrahend; // 生成借位条件
    
    // 使用生成和传播信号计算各位的借位
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : borrow_gen
            assign borrow[i+1] = g[i] | (p[i] & borrow[i]);
        end
    endgenerate
    
    // 计算减法结果
    assign sub_xor = minuend ^ subtrahend;
    assign difference = sub_xor ^ borrow[WIDTH-1:0];
    
endmodule

// XNOR操作子模块
module xnor_operation #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] result
);
    assign result = ~(a ^ b);
endmodule

// 按位与操作子模块
module bitwise_and #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] result
);
    assign result = a & b;
endmodule