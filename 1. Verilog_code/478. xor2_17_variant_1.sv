//SystemVerilog
// 顶层模块
module xor2_17 (
    input wire A, B, C, D,
    output wire Y
);
    wire stage1_out;
    
    // 实例化两个2输入XOR子模块
    xor_stage1 stage1_inst (
        .in1(A),
        .in2(B),
        .out(stage1_out)
    );
    
    xor_stage2 stage2_inst (
        .in1(stage1_out),
        .in2(C),
        .in3(D),
        .out(Y)
    );
endmodule

// 第一级XOR子模块，处理前两个输入
module xor_stage1 (
    input wire in1, in2,
    output wire out
);
    // 优化的XOR逻辑实现
    assign out = in1 ^ in2;
endmodule

// 第二级XOR子模块，处理剩余输入
module xor_stage2 (
    input wire in1, in2, in3,
    output wire out
);
    // 优化的三输入XOR实现
    // 分解为两个XOR操作以优化关键路径
    wire temp;
    
    assign temp = in1 ^ in2;
    assign out = temp ^ in3;
endmodule