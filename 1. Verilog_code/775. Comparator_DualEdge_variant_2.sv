//SystemVerilog
// 顶层模块
module Comparator_DualEdge #(parameter WIDTH = 8) (
    input              clk,
    input  [WIDTH-1:0] x, y,
    output             neq
);
    // 内部信号
    wire compare_result;
    
    // 实例化比较器子模块
    DataComparator #(
        .WIDTH(WIDTH)
    ) comp_unit (
        .x(x),
        .y(y),
        .result(compare_result)
    );
    
    // 实例化寄存器子模块
    RegisterUnit reg_unit (
        .clk(clk),
        .data_in(compare_result),
        .data_out(neq)
    );
endmodule

// 数据比较子模块
module DataComparator #(parameter WIDTH = 8) (
    input  [WIDTH-1:0] x, y,
    output             result
);
    // 纯组合逻辑比较
    assign result = (x != y);
endmodule

// 寄存器子模块
module RegisterUnit (
    input  clk,
    input  data_in,
    output reg data_out
);
    // 时序逻辑
    always @(posedge clk) begin
        data_out <= data_in;
    end
endmodule