//SystemVerilog
module RangeDetector_BoundType #(
    parameter WIDTH = 8,
    parameter INCLUSIVE = 1 // 0:exclusive
)(
    input clk,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] lower,
    input [WIDTH-1:0] upper,
    output reg out_flag
);

    wire in_range_inclusive;
    wire in_range_exclusive;
    
    // 使用减法和单次比较替代双重比较
    // 当 lower ≤ data_in ≤ upper 时，(data_in - lower) <= (upper - lower)
    // 针对有符号比较进行特殊处理
    wire [WIDTH:0] data_minus_lower = {1'b0, data_in} - {1'b0, lower};
    wire [WIDTH:0] upper_minus_lower = {1'b0, upper} - {1'b0, lower};
    
    assign in_range_inclusive = data_minus_lower <= upper_minus_lower;
    
    // 对于不包含边界的情况，需要确保data_in不等于边界值
    wire not_at_lower = data_in != lower;
    wire not_at_upper = data_in != upper;
    assign in_range_exclusive = in_range_inclusive & not_at_lower & not_at_upper;
    
    // 只有当lower <= upper时，范围检测才有意义
    wire valid_range = upper >= lower;
    
    always @(*) begin
        if (INCLUSIVE)
            out_flag = in_range_inclusive & valid_range;
        else
            out_flag = in_range_exclusive & valid_range;
    end
    
endmodule