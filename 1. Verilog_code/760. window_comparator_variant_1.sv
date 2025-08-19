//SystemVerilog
module window_comparator(
    input [11:0] data_value,
    input [11:0] lower_bound,
    input [11:0] upper_bound,
    output in_range,
    output out_of_range,
    output at_boundary
);
    // 使用减法和符号位比较，可以更好地映射到硬件比较器
    wire signed [12:0] diff_lower = $signed({1'b0, data_value}) - $signed({1'b0, lower_bound});
    wire signed [12:0] diff_upper = $signed({1'b0, data_value}) - $signed({1'b0, upper_bound});
    
    // 单比特状态检测
    wire equal_lower = (diff_lower == 0);
    wire equal_upper = (diff_upper == 0);
    wire below_lower = diff_lower[12]; // 符号位为1表示负数
    wire above_upper = !diff_upper[12] && (diff_upper != 0); // 符号位为0且不等于0表示正数
    
    // 组合逻辑简化
    assign at_boundary = equal_lower || equal_upper;
    assign out_of_range = below_lower || above_upper;
    assign in_range = !(out_of_range); // 直接使用out_of_range的反操作，减少冗余计算

    // 添加参数属性指导综合工具优化
    /* synthesis parallel_case full_case */
endmodule