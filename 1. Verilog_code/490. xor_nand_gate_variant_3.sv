//SystemVerilog
// 顶层模块 - 将XOR和NAND逻辑组合在一起
module xor_nand_gate (
    input wire A, B, C,   // 输入A, B, C
    output wire Y         // 输出Y
);
    wire xor_result;      // A和B的异或结果
    wire nand_result;     // A和C的与非结果
    wire and1_result;     // 第一个与门结果
    wire and2_result;     // 第二个与门结果

    // 实例化子模块
    xor_module xor_inst (
        .a(A),
        .b(B),
        .y(xor_result)
    );

    nand_module nand_inst (
        .a(A),
        .b(C),
        .y(nand_result)
    );

    logic_combine_module logic_combine_inst (
        .xor_in(xor_result),
        .nand_in(nand_result),
        .a(A),
        .b(B),
        .y(Y)
    );
endmodule

// 子模块1 - 异或操作
module xor_module (
    input wire a,
    input wire b,
    output wire y
);
    // 实现异或功能
    assign y = a ^ b;
endmodule

// 子模块2 - 与非操作
module nand_module (
    input wire a,
    input wire b,
    output wire y
);
    // 实现与非功能
    assign y = ~(a & b);
endmodule

// 子模块3 - 逻辑组合
module logic_combine_module (
    input wire xor_in,
    input wire nand_in,
    input wire a,
    input wire b,
    output wire y
);
    // 最终的组合逻辑
    assign y = (a & ~b & nand_in) | (~a & b);
endmodule