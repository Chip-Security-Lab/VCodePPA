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

    // Pipeline stages
    reg [WIDTH-1:0]     a_reg, b_reg;
    reg                 eq_reg;
    reg [HISTORY_DEPTH-1:0] history_reg;

    // Input stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= {WIDTH{1'b0}};
            b_reg <= {WIDTH{1'b0}};
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end

    // Comparison stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            eq_reg <= 1'b0;
        end else begin
            eq_reg <= (a_reg == b_reg);
        end
    end

    // History buffer stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            history_reg <= {HISTORY_DEPTH{1'b0}};
        end else begin
            history_reg <= {history_reg[HISTORY_DEPTH-2:0], eq_reg};
        end
    end

    // Output assignments
    assign curr_eq = eq_reg;
    assign history_eq = history_reg;

endmodule