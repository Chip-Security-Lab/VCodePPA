//SystemVerilog
module range_detector_sync(
    input wire clk, rst_n,
    input wire [7:0] data_in,
    input wire [7:0] lower_bound, upper_bound,
    output reg in_range
);
    wire compare_result;
    
    optimized_comparator comp_inst (
        .data(data_in),
        .lower(lower_bound),
        .upper(upper_bound),
        .result(compare_result)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            in_range <= 1'b0;
        else
            in_range <= compare_result;
    end
endmodule

module optimized_comparator(
    input wire [7:0] data,
    input wire [7:0] lower,
    input wire [7:0] upper,
    output wire result
);
    // 预先计算数据与上下边界的偏移量
    wire signed [8:0] lower_diff = {1'b0, data} - {1'b0, lower};
    wire signed [8:0] upper_diff = {1'b0, upper} - {1'b0, data};
    
    // 使用符号位直接判断范围，减少比较器级联
    // 如果lower_diff和upper_diff都是非负数，则data在范围内
    assign result = !lower_diff[8] && !upper_diff[8];
endmodule