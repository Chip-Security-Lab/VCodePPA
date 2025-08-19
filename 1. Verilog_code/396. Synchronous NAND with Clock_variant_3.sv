//SystemVerilog
// 顶层模块
module nand2_16 (
    input wire A, B,
    input wire clk,
    output reg Y
);
    // 内部连线
    wire nand_result;
    
    // 实例化布尔逻辑计算子模块
    boolean_logic_unit blu (
        .in_a(A),
        .in_b(B),
        .out_result(nand_result)
    );
    
    // 实例化时序控制子模块
    output_register oreg (
        .clk(clk),
        .data_in(nand_result),
        .data_out(Y)
    );
endmodule

// 布尔逻辑单元子模块 - 专注于组合逻辑计算
module boolean_logic_unit (
    input wire in_a,
    input wire in_b,
    output wire out_result
);
    // 应用德摩根定律实现NAND功能: ~(A & B) = (~A | ~B)
    assign out_result = (~in_a) | (~in_b);
endmodule

// 输出寄存器子模块 - 专注于时序控制
module output_register (
    input wire clk,
    input wire data_in,
    output reg data_out
);
    // 在时钟上升沿更新输出寄存器
    always @(posedge clk) begin
        data_out <= data_in;
    end
endmodule