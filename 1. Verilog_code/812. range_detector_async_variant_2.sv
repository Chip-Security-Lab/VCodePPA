//SystemVerilog
// Top-level module
module range_detector_async(
    input wire [15:0] data_in,
    input wire [15:0] min_val, max_val,
    output wire within_range
);
    // Instantiate submodules
    wire greater_than_min;
    wire less_than_max;
    
    // Lower bound check submodule
    lower_bound_check #(
        .DATA_WIDTH(16)
    ) lower_bound_inst (
        .data_in(data_in),
        .min_val(min_val),
        .greater_than_min(greater_than_min)
    );
    
    // Upper bound check submodule
    upper_bound_check #(
        .DATA_WIDTH(16)
    ) upper_bound_inst (
        .data_in(data_in),
        .max_val(max_val),
        .less_than_max(less_than_max)
    );
    
    // Range combination submodule
    range_combiner range_combiner_inst (
        .greater_than_min(greater_than_min),
        .less_than_max(less_than_max),
        .within_range(within_range)
    );
endmodule

// Lower bound check submodule
module lower_bound_check #(
    parameter DATA_WIDTH = 16
)(
    input wire [DATA_WIDTH-1:0] data_in,
    input wire [DATA_WIDTH-1:0] min_val,
    output wire greater_than_min
);
    assign greater_than_min = (data_in >= min_val);
endmodule

// Upper bound check submodule
module upper_bound_check #(
    parameter DATA_WIDTH = 16
)(
    input wire [DATA_WIDTH-1:0] data_in,
    input wire [DATA_WIDTH-1:0] max_val,
    output wire less_than_max
);
    assign less_than_max = (data_in <= max_val);
endmodule

// Range combination submodule
module range_combiner(
    input wire greater_than_min,
    input wire less_than_max,
    output wire within_range
);
    assign within_range = greater_than_min && less_than_max;
endmodule