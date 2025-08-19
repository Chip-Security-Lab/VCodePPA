//SystemVerilog
module Comparator_HistoryBuffer #(
    parameter WIDTH = 8,
    parameter HISTORY_DEPTH = 4
)(
    input               clk,
    input               rst_n,
    input  [WIDTH-1:0]  a,b,
    output              curr_eq,
    output [HISTORY_DEPTH-1:0] history_eq
);
    reg [HISTORY_DEPTH-1:0] history_reg;
    reg curr_eq_reg;
    wire compare_result;
    
    // 优化比较逻辑，采用异或后归约的方式实现相等比较
    assign compare_result = ~(|((a ^ b)));
    
    // 注册比较结果以提高时序性能
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) curr_eq_reg <= 1'b0;
        else        curr_eq_reg <= compare_result;
    end
    
    assign curr_eq = curr_eq_reg;
    
    // 分段实现历史记录移位以优化时序路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            history_reg <= {HISTORY_DEPTH{1'b0}};
        else begin
            history_reg[0] <= compare_result;
            history_reg[HISTORY_DEPTH-1:1] <= history_reg[HISTORY_DEPTH-2:0];
        end
    end
    
    assign history_eq = history_reg;
endmodule