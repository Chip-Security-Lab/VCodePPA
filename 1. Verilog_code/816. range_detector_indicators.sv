module range_detector_indicators(
    input wire [11:0] input_value,
    input wire [11:0] min_threshold, max_threshold,
    output wire in_range,
    output wire below_range,
    output wire above_range
);
    assign below_range = (input_value < min_threshold);
    assign above_range = (input_value > max_threshold);
    assign in_range = !(below_range || above_range);
endmodule