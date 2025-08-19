//SystemVerilog
module range_pattern_matcher #(parameter WIDTH = 8) (
    input clk, rst_n,
    input [WIDTH-1:0] data, lower_bound, upper_bound,
    output reg in_range
);
    wire lower_check, upper_check;
    wire [WIDTH-1:0] lower_diff, upper_diff;
    wire lower_borrow, upper_borrow;
    
    // 条件求和减法器实现 - 检查 data >= lower_bound
    assign {lower_borrow, lower_diff} = {1'b0, data} + {1'b0, ~lower_bound} + 1'b1;
    assign lower_check = ~lower_borrow;
    
    // 条件求和减法器实现 - 检查 data <= upper_bound
    assign {upper_borrow, upper_diff} = {1'b0, upper_bound} + {1'b0, ~data} + 1'b1;
    assign upper_check = ~upper_borrow;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            in_range <= 1'b0;
        else
            in_range <= lower_check && upper_check;
    end
endmodule