//SystemVerilog
module range_pattern_matcher #(parameter WIDTH = 8) (
    input clk, rst_n,
    input [WIDTH-1:0] data, lower_bound, upper_bound,
    output reg in_range
);
    // 中间信号声明，用于分离比较逻辑和更新逻辑
    reg greater_equal_lower; // 表示数据大于等于下界
    reg less_equal_upper;    // 表示数据小于等于上界
    
    // 比较逻辑 - 检查数据是否大于等于下界
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            greater_equal_lower <= 1'b0;
        else
            greater_equal_lower <= (data >= lower_bound);
    end
    
    // 比较逻辑 - 检查数据是否小于等于上界
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            less_equal_upper <= 1'b0;
        else
            less_equal_upper <= (data <= upper_bound);
    end
    
    // 组合逻辑 - 根据两个比较结果确定是否在范围内
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            in_range <= 1'b0;
        else
            in_range <= greater_equal_lower && less_equal_upper;
    end
endmodule