//SystemVerilog
module range_pattern_matcher #(parameter WIDTH = 8) (
    input clk, rst_n,
    input [WIDTH-1:0] data, lower_bound, upper_bound,
    output reg in_range
);
    // 预计算比较结果以提高性能
    wire lb_check, ub_check;
    
    // 使用专用比较器
    assign lb_check = (data >= lower_bound);
    assign ub_check = (data <= upper_bound);
    
    // 注册逻辑优化
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            in_range <= 1'b0;
        else
            in_range <= lb_check & ub_check; // 使用位与(&)替代逻辑与(&&)以减少逻辑层级
    end
endmodule