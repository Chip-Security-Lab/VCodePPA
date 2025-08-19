//SystemVerilog

// 顶层模块
module nand4_2 (
    input  wire A,
    input  wire B,
    input  wire C,
    input  wire D,
    output wire Y
);
    // 使用NOR-NOR实现结构代替直接NAND实现
    // 利用德摩根定律: ~(A & B & C & D) = ~A | ~B | ~C | ~D
    // 进一步优化为二级NOR结构: ~(~(~A | ~B) | ~(~C | ~D))
    
    wire nor_ab, nor_cd, nor_output;
    
    // 第一级NOR
    assign #1 nor_ab = ~(~A | ~B);
    assign #1 nor_cd = ~(~C | ~D);
    
    // 第二级NOR实现
    assign #0.5 nor_output = ~(nor_ab | nor_cd);
    
    // 输出
    assign #0.5 Y = nor_output;
    
endmodule

// 保留子模块定义以实现API向后兼容性

// 4输入与门子模块
module and4_submodule (
    input  wire in_a,
    input  wire in_b,
    input  wire in_c,
    input  wire in_d,
    output wire out_and
);
    parameter DELAY = 1;
    
    // 使用二级与结构实现，减少扇入
    wire ab, cd;
    assign #(DELAY/2) ab = in_a & in_b;
    assign #(DELAY/2) cd = in_c & in_d;
    assign #(DELAY/2) out_and = ab & cd;
endmodule

// 反相器子模块
module inverter_submodule (
    input  wire in_signal,
    output wire out_signal
);
    parameter INV_DELAY = 1;
    
    // 保持原有实现但优化延迟模型
    assign #INV_DELAY out_signal = ~in_signal;
endmodule