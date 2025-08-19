//SystemVerilog
//===================================================================
// 项目: 高效XOR门实现
// 描述: 分层实现的2输入XOR门
// 标准: IEEE 1364-2005
//===================================================================

//===================================================================
// 顶层模块: xor2_13
//===================================================================
module xor2_13 #(
    parameter TIMING_OPTIMIZATION = 1  // 参数化设计提高复用性
)(
    input  wire A,     // 第一输入信号
    input  wire B,     // 第二输入信号
    output wire Y      // 输出信号
);
    // 内部连接信号
    wire nand_out1;
    wire nand_out2;
    
    // 实例化NAND逻辑子模块实现XOR功能
    // 将XOR分解为NAND实现，改善延迟特性
    nand_gate_module nand1 (
        .in_a(A),
        .in_b(B),
        .out_y(nand_out1)
    );
    
    nand_gate_module nand2 (
        .in_a(A),
        .in_b(nand_out1),
        .out_y(nand_out2)
    );
    
    nand_gate_module nand3 (
        .in_a(nand_out1),
        .in_b(B),
        .out_y(Y)
    );
    
endmodule

//===================================================================
// NAND门子模块
//===================================================================
module nand_gate_module (
    input  wire in_a,
    input  wire in_b,
    output wire out_y
);
    // 使用连续赋值提高时序性能
    assign out_y = ~(in_a & in_b);
endmodule