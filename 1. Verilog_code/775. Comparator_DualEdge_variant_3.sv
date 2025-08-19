//SystemVerilog
// 顶层模块
module Comparator_DualEdge #(parameter WIDTH = 8) (
    input              clk,
    input  [WIDTH-1:0] x, y,
    output             neq
);
    // 内部连线
    wire comparison_result;
    
    // 比较逻辑子模块实例化
    ComparisonLogic #(
        .WIDTH(WIDTH)
    ) comparison_unit (
        .x(x),
        .y(y),
        .result(comparison_result)
    );
    
    // 时序控制子模块实例化
    OutputRegister output_reg_unit (
        .clk(clk),
        .data_in(comparison_result),
        .data_out(neq)
    );
endmodule

// 比较逻辑子模块
module ComparisonLogic #(parameter WIDTH = 8) (
    input      [WIDTH-1:0] x, y,
    output reg             result
);
    // 纯组合逻辑比较操作，减少关键路径延迟
    always @(*) begin
        result = (x != y);
    end
endmodule

// 时序控制子模块
module OutputRegister (
    input  clk,
    input  data_in,
    output reg data_out
);
    // 将原始时序逻辑隔离，便于时序优化
    always @(posedge clk) begin
        data_out <= data_in;
    end
endmodule