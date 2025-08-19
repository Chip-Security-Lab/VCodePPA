//SystemVerilog
//=====================================================================
// Top level module - Open-ended Range Detector
//=====================================================================
module open_ended_range_detector(
    input wire [11:0] data,
    input wire [11:0] bound_value,
    input wire direction, // 0=lower_bound_only, 1=upper_bound_only
    output wire in_valid_zone
);
    // Internal connections
    wire lower_bound_result;
    wire upper_bound_result;
    
    // Instantiate lower bound detector
    lower_bound_detector lower_bound_inst (
        .data(data),
        .bound_value(bound_value),
        .is_in_range(lower_bound_result)
    );
    
    // Instantiate upper bound detector
    upper_bound_detector upper_bound_inst (
        .data(data),
        .bound_value(bound_value),
        .is_in_range(upper_bound_result)
    );
    
    // Instantiate result selector based on direction
    result_selector result_selector_inst (
        .lower_bound_result(lower_bound_result),
        .upper_bound_result(upper_bound_result),
        .direction(direction),
        .final_result(in_valid_zone)
    );
endmodule

//=====================================================================
// Lower bound detector submodule
//=====================================================================
module lower_bound_detector #(
    parameter DATA_WIDTH = 12
)(
    input wire [DATA_WIDTH-1:0] data,
    input wire [DATA_WIDTH-1:0] bound_value,
    output wire is_in_range
);
    // Check if data is greater than or equal to the bound_value
    assign is_in_range = (data >= bound_value);
endmodule

//=====================================================================
// Upper bound detector submodule
//=====================================================================
module upper_bound_detector #(
    parameter DATA_WIDTH = 12
)(
    input wire [DATA_WIDTH-1:0] data,
    input wire [DATA_WIDTH-1:0] bound_value,
    output wire is_in_range
);
    // Check if data is less than or equal to the bound_value
    assign is_in_range = (data <= bound_value);
endmodule

//=====================================================================
// Result selector submodule
//=====================================================================
module result_selector(
    input wire lower_bound_result,
    input wire upper_bound_result,
    input wire direction, // 0=lower_bound_only, 1=upper_bound_only
    output wire final_result
);
    // Select the appropriate result based on direction
    assign final_result = direction ? upper_bound_result : lower_bound_result;
endmodule