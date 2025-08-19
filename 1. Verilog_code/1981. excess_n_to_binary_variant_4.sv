//SystemVerilog
// Top-level Module: Hierarchical Excess-N to Binary Converter (Refactored)
module excess_n_to_binary #(
    parameter WIDTH = 8,
    parameter N = 127
)(
    input  wire [WIDTH-1:0] excess_n_in,
    output wire [WIDTH-1:0] binary_out
);

    // Internal signal for subtraction result
    wire [WIDTH-1:0] subtracted_result;

    // Instantiate Subtractor Unit
    excess_n_subtractor #(
        .WIDTH(WIDTH),
        .N(N)
    ) u_excess_n_subtractor (
        .excess_n_in(excess_n_in),
        .subtracted_value(subtracted_result)
    );

    // Instantiate Output Register Unit
    binary_output_register #(
        .WIDTH(WIDTH)
    ) u_binary_output_register (
        .in_value(subtracted_result),
        .binary_out(binary_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: Excess-N Subtractor
// Performs subtraction of the Excess-N bias from the input value.
// -----------------------------------------------------------------------------
module excess_n_subtractor #(
    parameter WIDTH = 8,
    parameter N = 127
)(
    input  wire [WIDTH-1:0] excess_n_in,
    output wire [WIDTH-1:0] subtracted_value
);
    assign subtracted_value = excess_n_in - N;
endmodule

// -----------------------------------------------------------------------------
// Submodule: Binary Output Register
// Latches the subtraction result to the output (combinational).
// -----------------------------------------------------------------------------
module binary_output_register #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] in_value,
    output wire [WIDTH-1:0] binary_out
);
    assign binary_out = in_value;
endmodule