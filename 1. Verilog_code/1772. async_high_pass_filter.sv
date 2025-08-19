module async_high_pass_filter #(
    parameter DATA_WIDTH = 10
)(
    input [DATA_WIDTH-1:0] signal_input,
    input [DATA_WIDTH-1:0] avg_input,  // Moving average input
    output [DATA_WIDTH-1:0] filtered_out
);
    // High-pass: removes low frequency (DC) components
    assign filtered_out = signal_input - avg_input;
endmodule