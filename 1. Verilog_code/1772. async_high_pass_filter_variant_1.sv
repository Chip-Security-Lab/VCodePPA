//SystemVerilog
/////////////////////////////////////////////////////////
// Top Level Module - High Pass Filter
/////////////////////////////////////////////////////////
module async_high_pass_filter #(
    parameter DATA_WIDTH = 10
)(
    input [DATA_WIDTH-1:0] signal_input,
    input [DATA_WIDTH-1:0] avg_input,  // Moving average input
    output [DATA_WIDTH-1:0] filtered_out
);
    // Instantiate subtraction module
    subtraction_unit #(
        .DATA_WIDTH(DATA_WIDTH)
    ) hp_filter_core (
        .minuend(signal_input),
        .subtrahend(avg_input),
        .difference(filtered_out)
    );
endmodule

/////////////////////////////////////////////////////////
// Subtraction Unit - Core Computation Component
/////////////////////////////////////////////////////////
module subtraction_unit #(
    parameter DATA_WIDTH = 10
)(
    input [DATA_WIDTH-1:0] minuend,     // Signal to be processed
    input [DATA_WIDTH-1:0] subtrahend,  // Value to subtract (average)
    output [DATA_WIDTH-1:0] difference  // High-pass filtered result
);
    // Compute difference to remove low frequency components
    assign difference = minuend - subtrahend;
endmodule