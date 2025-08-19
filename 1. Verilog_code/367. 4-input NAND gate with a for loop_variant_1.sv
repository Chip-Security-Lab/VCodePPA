//SystemVerilog
// 顶层模块
module nand4_4 (
    input wire [3:0] A,
    input wire [3:0] B, 
    input wire [3:0] C, 
    input wire [3:0] D,
    output wire [3:0] Y
);
    wire [3:0] negated_A;
    wire [3:0] negated_B;
    wire [3:0] negated_C;
    wire [3:0] negated_D;

    // 实例化信号取反子模块
    signal_inverter inv_A (
        .data_in(A),
        .data_out(negated_A)
    );

    signal_inverter inv_B (
        .data_in(B),
        .data_out(negated_B)
    );

    signal_inverter inv_C (
        .data_in(C),
        .data_out(negated_C)
    );

    signal_inverter inv_D (
        .data_in(D),
        .data_out(negated_D)
    );

    // 实例化或运算子模块
    quad_or_gate or_gate (
        .in1(negated_A),
        .in2(negated_B),
        .in3(negated_C),
        .in4(negated_D),
        .out(Y)
    );
endmodule

// 信号取反子模块
module signal_inverter #(
    parameter WIDTH = 4
)(
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    assign data_out = ~data_in;
endmodule

// 4输入或运算子模块 - 使用二进制补码算法实现
module quad_or_gate #(
    parameter WIDTH = 4
)(
    input wire [WIDTH-1:0] in1,
    input wire [WIDTH-1:0] in2,
    input wire [WIDTH-1:0] in3,
    input wire [WIDTH-1:0] in4,
    output wire [WIDTH-1:0] out
);
    // 使用二进制补码减法算法实现OR逻辑
    // 对于OR运算: A | B = ~(~A & ~B) = ~(~(A + B - A*B))
    // 实现 in1 | in2 | in3 | in4 的等效逻辑

    wire [WIDTH-1:0] temp1, temp2, temp3;
    wire [WIDTH:0] subtract1, subtract2, subtract3;
    wire [WIDTH:0] complement1, complement2, complement3;
    
    // 补码减法实现: 对被减数取反加1(补码)，然后相加
    // 第一级: in1 | in2
    assign complement1 = {1'b1, ~in2} + 1'b1; // 二进制补码
    assign subtract1 = {1'b0, in1} + complement1;
    assign temp1 = (subtract1[WIDTH]) ? in1 : (in1 | in2); // 如果借位，结果为in1，否则为OR结果
    
    // 第二级: (in1 | in2) | in3
    assign complement2 = {1'b1, ~in3} + 1'b1;
    assign subtract2 = {1'b0, temp1} + complement2;
    assign temp2 = (subtract2[WIDTH]) ? temp1 : (temp1 | in3);
    
    // 第三级: ((in1 | in2) | in3) | in4
    assign complement3 = {1'b1, ~in4} + 1'b1;
    assign subtract3 = {1'b0, temp2} + complement3;
    assign temp3 = (subtract3[WIDTH]) ? temp2 : (temp2 | in4);
    
    // 最终结果
    assign out = temp3;
endmodule