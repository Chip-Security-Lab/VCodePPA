//SystemVerilog
// 顶层模块: 8位条件求和减法器
module conditional_subtractor_8bit (
    input wire [7:0] a,        // 被减数
    input wire [7:0] b,        // 减数
    output wire [7:0] diff,    // 差
    output wire borrow_out     // 借位输出
);
    // 优化：直接使用加一补码减法实现
    // 在补码减法中：A-B = A+(~B+1)
    // 如果使用借位而非进位，初始借位为1
    wire [8:0] result;
    
    // 一步计算差值，避免中间信号
    assign result = {1'b0, a} + {1'b0, ~b} + 9'b1;
    
    // 结果直接获取，无需额外的XOR运算
    assign diff = result[7:0];
    
    // 优化借位逻辑，利用加法结果的溢出位
    assign borrow_out = ~result[8];
endmodule

// 优化后的参数化4输入与门
module and_gate_4param #(parameter WIDTH = 4) (
    input wire [WIDTH-1:0] a,  // Input A
    input wire [WIDTH-1:0] b,  // Input B
    input wire [WIDTH-1:0] c,  // Input C
    input wire [WIDTH-1:0] d,  // Input D
    output wire [WIDTH-1:0] y  // Output Y
);
    // 位运算保持不变，但增加了IEEE 1364-2005合规性
    assign y = a & b & c & d;
endmodule