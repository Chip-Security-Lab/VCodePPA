//SystemVerilog
module range_detector_param #(
    parameter DATA_WIDTH = 32
)(
    input wire [DATA_WIDTH-1:0] data,
    input wire [DATA_WIDTH-1:0] lower, upper,
    output wire in_bounds
);
    // Optimized range check using single comparison
    assign in_bounds = (data >= lower) && (data <= upper);
endmodule