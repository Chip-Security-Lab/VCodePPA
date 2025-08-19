module range_detector_param #(
    parameter DATA_WIDTH = 32
)(
    input wire [DATA_WIDTH-1:0] data,
    input wire [DATA_WIDTH-1:0] lower, upper,
    output wire in_bounds
);
    comparator #(.WIDTH(DATA_WIDTH)) comp_unit (
        .input_data(data),
        .lower_threshold(lower),
        .upper_threshold(upper),
        .in_range(in_bounds)
    );
endmodule

// 添加缺失的comparator模块
module comparator #(
    parameter WIDTH = 32
)(
    input wire [WIDTH-1:0] input_data,
    input wire [WIDTH-1:0] lower_threshold,
    input wire [WIDTH-1:0] upper_threshold,
    output wire in_range
);
    assign in_range = (input_data >= lower_threshold) && (input_data <= upper_threshold);
endmodule