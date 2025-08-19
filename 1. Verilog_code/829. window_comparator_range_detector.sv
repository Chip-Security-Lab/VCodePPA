module window_comparator_range_detector(
    input wire [9:0] analog_value,
    input wire [9:0] window_center,
    input wire [9:0] window_width,
    output wire in_window
);
    wire [9:0] half_width = window_width >> 1;
    wire [9:0] lower_threshold = window_center - half_width;
    wire [9:0] upper_threshold = window_center + half_width;
    
    assign in_window = (analog_value >= lower_threshold) && 
                       (analog_value <= upper_threshold);
endmodule