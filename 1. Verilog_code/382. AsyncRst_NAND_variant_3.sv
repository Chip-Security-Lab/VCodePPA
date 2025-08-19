//SystemVerilog
module AsyncRst_NAND(
    input rst_n,
    input [3:0] src1, src2,
    output [3:0] q
);
    // 直接在顶层模块实现逻辑，减少层级和门延迟
    // 使用组合逻辑实现NAND操作和复位控制
    // 优化：合并NAND操作和复位控制到一个表达式，减少中间寄存器
    assign q = rst_n ? (src1 | ~src2) & (~src1 | ~src2) : 4'b1111;
endmodule

// NAND逻辑运算子模块 - 使用布尔代数简化
// ~(A & B) = ~A | ~B (德摩根定律)
module NAND_Operation(
    input [3:0] in1,
    input [3:0] in2,
    output [3:0] out
);
    assign out = (~in1) | (~in2);
endmodule

// 复位控制子模块 - 改为非阻塞赋值以避免竞争冒险
module Reset_Control(
    input rst_n,
    input [3:0] data_in,
    output reg [3:0] data_out
);
    always @(*) begin
        data_out <= rst_n ? data_in : 4'b1111;
    end
endmodule