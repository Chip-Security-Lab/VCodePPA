//SystemVerilog
// Top level module
module async_peak_detector #(
    parameter W = 12
)(
    input [W-1:0] signal_in,
    input [W-1:0] current_peak,
    input reset_peak,
    output [W-1:0] peak_out
);
    wire [W-1:0] comparison_result;
    wire [W-1:0] reset_result;

    // Instantiate comparator submodule
    peak_comparator #(
        .WIDTH(W)
    ) comparator_inst (
        .in_signal(signal_in),
        .current_peak(current_peak),
        .greater_value(comparison_result)
    );

    // Instantiate reset handler submodule
    peak_reset_handler #(
        .WIDTH(W)
    ) reset_handler_inst (
        .signal_in(signal_in),
        .comparison_result(comparison_result),
        .reset_peak(reset_peak),
        .peak_out(peak_out)
    );
endmodule

// Submodule for comparing input signal with current peak
module peak_comparator #(
    parameter WIDTH = 12
)(
    input [WIDTH-1:0] in_signal,
    input [WIDTH-1:0] current_peak,
    output [WIDTH-1:0] greater_value
);
    // Compare input signal with current peak and select the greater value
    assign greater_value = (in_signal > current_peak) ? in_signal : current_peak;
endmodule

// Submodule for handling peak reset functionality
module peak_reset_handler #(
    parameter WIDTH = 12
)(
    input [WIDTH-1:0] signal_in,
    input [WIDTH-1:0] comparison_result,
    input reset_peak,
    output [WIDTH-1:0] peak_out
);
    // Select between reset value and comparison result
    assign peak_out = reset_peak ? signal_in : comparison_result;
endmodule