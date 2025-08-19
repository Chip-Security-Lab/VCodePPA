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
    
    assign curr_eq = (a == b);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) history_reg <= {HISTORY_DEPTH{1'b0}};
        else        history_reg <= {history_reg[HISTORY_DEPTH-2:0], curr_eq};
    end
    
    assign history_eq = history_reg;
endmodule