//SystemVerilog
module RangeDetector_AsyncMultiZone #(
    parameter ZONES = 4,
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] bounds [ZONES*2-1:0],
    output [ZONES-1:0] zone_flags
);
    // Internal wires for connecting submodules
    wire [WIDTH-1:0] zone_lower_bounds [ZONES-1:0];
    wire [WIDTH-1:0] zone_upper_bounds [ZONES-1:0];
    
    // Extract lower and upper bounds for each zone
    BoundsExtractor #(
        .ZONES(ZONES),
        .WIDTH(WIDTH)
    ) bounds_extractor_inst (
        .bounds(bounds),
        .zone_lower_bounds(zone_lower_bounds),
        .zone_upper_bounds(zone_upper_bounds)
    );
    
    // Zone detection logic for all zones
    ZoneDetector #(
        .ZONES(ZONES),
        .WIDTH(WIDTH)
    ) zone_detector_inst (
        .data_in(data_in),
        .zone_lower_bounds(zone_lower_bounds),
        .zone_upper_bounds(zone_upper_bounds),
        .zone_flags(zone_flags)
    );
endmodule

// Extracts and separates the lower and upper bounds for each zone
module BoundsExtractor #(
    parameter ZONES = 4,
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] bounds [ZONES*2-1:0],
    output [WIDTH-1:0] zone_lower_bounds [ZONES-1:0],
    output [WIDTH-1:0] zone_upper_bounds [ZONES-1:0]
);
    genvar i;
    generate
        for(i=0; i<ZONES; i=i+1) begin : extract_bounds
            // Extract lower bound (even index)
            assign zone_lower_bounds[i] = bounds[2*i];
            // Extract upper bound (odd index)
            assign zone_upper_bounds[i] = bounds[2*i+1];
        end
    endgenerate
endmodule

// Performs the actual zone detection by comparing data with each zone's bounds
module ZoneDetector #(
    parameter ZONES = 4,
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] zone_lower_bounds [ZONES-1:0],
    input [WIDTH-1:0] zone_upper_bounds [ZONES-1:0],
    output [ZONES-1:0] zone_flags
);
    genvar i;
    generate
        for(i=0; i<ZONES; i=i+1) begin : detect_zones
            // Instantiate single zone comparator for each zone
            SingleZoneComparator #(
                .WIDTH(WIDTH)
            ) zone_comp_inst (
                .data_in(data_in),
                .lower_bound(zone_lower_bounds[i]),
                .upper_bound(zone_upper_bounds[i]),
                .in_zone(zone_flags[i])
            );
        end
    endgenerate
endmodule

// Performs comparison for a single zone
module SingleZoneComparator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] lower_bound,
    input [WIDTH-1:0] upper_bound,
    output in_zone
);
    // Check if data is within bounds (inclusive)
    wire above_or_equal_lower = (data_in >= lower_bound);
    wire below_or_equal_upper = (data_in <= upper_bound);
    
    // Data is in zone if both conditions are true
    assign in_zone = above_or_equal_lower && below_or_equal_upper;
endmodule