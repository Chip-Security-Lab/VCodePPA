//SystemVerilog
// Top-level module: integer_to_fraction
// Function: Converts an integer input to a fixed-point fraction by shifting and dividing.
// Structure: Hierarchical, with two submodules: IntExtender and Divider.

module integer_to_fraction #(
    parameter INT_WIDTH = 8,
    parameter FRAC_WIDTH = 8
)(
    input  wire [INT_WIDTH-1:0] int_in,
    input  wire [INT_WIDTH-1:0] denominator,
    output wire [INT_WIDTH+FRAC_WIDTH-1:0] frac_out
);

    // Internal signal for extended integer value
    wire [INT_WIDTH+FRAC_WIDTH-1:0] extended_int;

    // Integer extension submodule
    IntExtender #(
        .INT_WIDTH(INT_WIDTH),
        .FRAC_WIDTH(FRAC_WIDTH)
    ) u_int_extender (
        .int_in(int_in),
        .extended_int(extended_int)
    );

    // Division submodule
    Divider #(
        .DATA_WIDTH(INT_WIDTH+FRAC_WIDTH)
    ) u_divider (
        .numerator(extended_int),
        .denominator(denominator),
        .quotient(frac_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: IntExtender
// Function: Shifts the integer input left by FRAC_WIDTH bits to prepare for fixed-point division.
// -----------------------------------------------------------------------------
module IntExtender #(
    parameter INT_WIDTH = 8,
    parameter FRAC_WIDTH = 8
)(
    input  wire [INT_WIDTH-1:0] int_in,
    output wire [INT_WIDTH+FRAC_WIDTH-1:0] extended_int
);
    assign extended_int = {{(FRAC_WIDTH){1'b0}}, int_in} << FRAC_WIDTH;
endmodule

// -----------------------------------------------------------------------------
// Submodule: Divider
// Function: Performs division of the extended integer by the denominator.
// -----------------------------------------------------------------------------
module Divider #(
    parameter DATA_WIDTH = 16
)(
    input  wire [DATA_WIDTH-1:0] numerator,
    input  wire [(DATA_WIDTH/2)-1:0] denominator,
    output wire [DATA_WIDTH-1:0] quotient
);
    assign quotient = denominator != 0 ? numerator / denominator : {DATA_WIDTH{1'b0}};
endmodule