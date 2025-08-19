//SystemVerilog
module Comparator_HistoryBuffer #(
    parameter WIDTH = 8,
    parameter HISTORY_DEPTH = 4 // 存储深度可配置
)(
    input               clk,
    input               rst_n,
    input  [WIDTH-1:0]  a,b,
    output              curr_eq,
    output [HISTORY_DEPTH-1:0] history_eq
);
    reg [HISTORY_DEPTH-1:0] history_reg;
    wire [WIDTH-1:0] diff;
    wire [WIDTH:0] sum_with_borrow;
    wire [WIDTH-1:0] b_inv;
    
    // 条件求和减法算法实现
    // 获取b的反码
    assign b_inv = ~b;
    // 执行a + ~b + 1 (等价于a - b)
    assign sum_with_borrow = a + b_inv + 1'b1;
    // 计算差值
    assign diff = sum_with_borrow[WIDTH-1:0];
    // 判断是否相等 (差值为0表示相等)
    assign curr_eq = (diff == {WIDTH{1'b0}});
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) history_reg <= {HISTORY_DEPTH{1'b0}};
        else        history_reg <= {history_reg[HISTORY_DEPTH-2:0], curr_eq};
    end
    
    assign history_eq = history_reg;
endmodule