//SystemVerilog
module window_comparator_range_detector(
    input wire [9:0] analog_value,
    input wire [9:0] window_center,
    input wire [9:0] window_width,
    output wire in_window
);
    // Optimized implementation using a single comparison with range check
    // Avoid unnecessary intermediate signals and calculations
    
    // Calculate half_width using barrel shifter (division by 2)
    wire [9:0] half_width = {1'b0, window_width[9:1]};
    
    // Optimized window detection using a single comparison
    // This reduces the number of comparators needed
    wire [9:0] distance_from_center;
    assign distance_from_center = (analog_value > window_center) ? 
                                  (analog_value - window_center) : 
                                  (window_center - analog_value);
    
    // Final comparison is now a simple range check
    assign in_window = (distance_from_center <= half_width);
endmodule