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
    // 使用补码加法实现比较操作
    wire [WIDTH:0] lower_diff, upper_diff;
    wire lower_gte, upper_gte;
    
    // 计算data_in与lower和upper的差值
    // 使用补码加法：a-b = a+~b+1
    assign lower_diff = {1'b0, data_in} + {1'b0, ~lower} + 1'b1;
    assign upper_diff = {1'b0, upper} + {1'b0, ~data_in} + 1'b1;
    
    // 简化比较逻辑
    // data_in >= lower 当且仅当 data_in - lower >= 0，即 lower_diff[WIDTH] == 0
    assign lower_gte = ~lower_diff[WIDTH];
    // upper >= data_in 当且仅当 upper - data_in >= 0，即 upper_diff[WIDTH] == 0
    assign upper_gte = ~upper_diff[WIDTH];
    
    // 根据包含/排除参数生成结果
    always @(*) begin
        if(INCLUSIVE)
            // 包含边界：data_in >= lower && data_in <= upper
            out_flag = lower_gte && upper_gte;
        else
            // 排除边界：data_in > lower && data_in < upper
            out_flag = lower_gte && upper_gte && 
                      (lower_diff[WIDTH-1:0] != {WIDTH{1'b0}}) && 
                      (upper_diff[WIDTH-1:0] != {WIDTH{1'b0}});
    end
endmodule