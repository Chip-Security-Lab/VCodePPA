module range_detector_async(
    input wire [15:0] data_in,
    input wire [15:0] min_val, max_val,
    output wire within_range
);
    // Combinational comparator implementation
    wire above_min, below_max;
    
    assign above_min = (data_in >= min_val);
    assign below_max = (data_in <= max_val);
    assign within_range = above_min && below_max;
endmodule