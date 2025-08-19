//SystemVerilog
module Comparator_HistoryBuffer #(
    parameter WIDTH = 8,
    parameter HISTORY_DEPTH = 4
)(
    input               clk,
    input               rst_n,
    input  [WIDTH-1:0]  a,
    input  [WIDTH-1:0]  b,
    output              curr_eq,
    output [HISTORY_DEPTH-1:0] history_eq
);

    // 历史记录移位寄存器
    reg [HISTORY_DEPTH-1:0] history_reg;
    
    // 输入寄存器
    reg [WIDTH-1:0] a_reg;
    reg [WIDTH-1:0] b_reg;
    
    // 当前比较结果
    wire curr_eq_wire;
    
    // 输入寄存器逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= {WIDTH{1'b0}};
            b_reg <= {WIDTH{1'b0}};
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end
    
    // 当前比较逻辑
    assign curr_eq_wire = (a_reg == b_reg);

    // 历史记录更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            history_reg <= {HISTORY_DEPTH{1'b0}};
        end else begin
            history_reg <= {history_reg[HISTORY_DEPTH-2:0], curr_eq_wire};
        end
    end

    // 输出赋值
    assign curr_eq = curr_eq_wire;
    assign history_eq = history_reg;

endmodule