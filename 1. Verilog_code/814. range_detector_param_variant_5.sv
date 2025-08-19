//SystemVerilog
module range_detector_param #(
    parameter DATA_WIDTH = 32
)(
    input wire [DATA_WIDTH-1:0] data,
    input wire [DATA_WIDTH-1:0] lower, upper,
    output wire in_bounds
);
    wire [DATA_WIDTH-1:0] lower_diff, upper_diff;
    
    assign lower_diff = data - lower;
    assign upper_diff = upper - data;
    
    assign in_bounds = ~(lower_diff[DATA_WIDTH-1] | upper_diff[DATA_WIDTH-1]);
endmodule